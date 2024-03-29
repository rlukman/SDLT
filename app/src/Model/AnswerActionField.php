<?php

/**
 * This file contains the "AnswerActionField" class.
 *
 * @category SilverStripe_Project
 * @package SDLT
 * @author  Catalyst I.T.
 * @copyright 2019 New Zealand Transport Agency
 * @license https://nzta.govt.nz (BSD-3)
 * @link https://nzta.govt.nz
 */

namespace NZTA\SDLT\Model;

use SilverStripe\Forms\DropdownField;
use SilverStripe\Forms\FieldList;
use SilverStripe\GraphQL\Scaffolding\Interfaces\ScaffoldingProvider;
use SilverStripe\GraphQL\Scaffolding\Scaffolders\SchemaScaffolder;
use SilverStripe\ORM\DataObject;
use SilverStripe\Core\Convert;
use SilverStripe\Security\Member;
use SilverStripe\Security\Security;
use Symbiote\GridFieldExtensions\GridFieldOrderableRows;

/**
 * Class AnswerActionField
 *
 * There are different types of action, and the CMS interface will be changed dynamically based on the type
 *
 * @property string Label
 * @property string Title
 * @property string Type
 * @property string Message
 *
 * @property Task Task
 * @property Question Goto
 * @property Question Question
 *
 * @method Task Task()
 * @method Question Goto()
 * @method Question Question()
 */
class AnswerActionField extends DataObject implements ScaffoldingProvider
{
    /**
     * @var string
     */
    private static $table_name = 'AnswerActionField';

    /**
     * @var array
     */
    private static $db = [
        'Label' => 'Varchar(255)',
        'ActionType' => 'Enum(array("continue", "goto", "message", "finish"))',
        'Message' => 'HTMLText',
        'SortOrder' => 'Int',
        'Result' => 'Varchar(255)'
    ];

    /**
     * @var array
     */
    private static $has_one = [
        'Task' => Task::class,
        'Goto' => Question::class,
        'Question' => Question::class
    ];

    /**
     * @var array
     */
    private static $summary_fields = [
        'Label',
        'ActionType',
        'ActionDescription',
        'Task.Name' => 'Create Task'
    ];

    /**
     * @var array
     */
    private static $field_labels = [
        'Label' => 'Action Label'
    ];

    /**
     * @var string
     */
    private static $default_sort = 'SortOrder';

    /**
     * @return FieldList
     */
    public function getCMSFields()
    {
        $fields = parent::getCMSFields();

        $fields->removeByName(['QuestionID', 'SortOrder']);

        //Questions are used on both Task and Questionnaire: we don't know which
        //one this action field applies to, so we need to merge the sets of both
        //in rare cases, the question may be used on both a Questionnaire and a
        //task
        $questionList =
            $this->Question()->Task()->Questions()->map()->toArray()
            +
            $this->Question()->Questionnaire()->Questions()->map()->toArray();

        /* @var $taskField DropdownField */
        $taskField = $fields->dataFieldByName('TaskID');
        $taskField
            ->setTitle('Create Task')
            ->setEmptyString('-- No task will be created --')
            ->setDescription('If the user choose this action, the associated task will be created');

        $fields->dataFieldByName('Result')->setDescription('The result will be used only if Questionnaire type is a task.');

        $fields->addFieldToTab('Root.Main', DropdownField::create('GotoID', 'Go to', $questionList));

        /** @noinspection PhpUndefinedMethodInspection */
        $fields->dataFieldByName('GotoID')->displayIf('ActionType')->isEqualTo('goto');

        /** @noinspection PhpUndefinedMethodInspection */
        $fields->dataFieldByName('Message')->displayIf('ActionType')->isEqualTo('message');

        /** @noinspection PhpUndefinedMethodInspection */
        $fields->dataFieldByName('Result')->displayIf('ActionType')->isEqualTo('finish');

        return $fields;
    }

    /**
     * @param SchemaScaffolder $scaffolder Scaffolder
     * @return SchemaScaffolder
     */
    public function provideGraphQLScaffolding(SchemaScaffolder $scaffolder)
    {
        // Provide entity type
        $typeScaffolder = $scaffolder
            ->type(AnswerActionField::class)
            ->addFields([
                'ID',
                'Label',
                'ActionType',
                'Message',
                'Task',
                'Goto',
            ]);

        return $scaffolder;
    }

    /**
     * @return string
     */
    public function getActionDescription()
    {
        switch ($this->ActionType) {
            case 'goto':
                $question = $this->Goto->exists() ? $this->Goto->Title : "Null";
                return "Goto: {$question}";
            case 'message':
                return "Message: " . Convert::xml2raw($this->Message);
            case 'continue':
                return 'Continue';
            case 'finish':
                return 'Finish';
            default:
                return "Unknown";
        }
    }

    /**
     * Allow logged-in user to access the model
     *
     * @param Member|null $member member
     * @return bool
     */
    public function canView($member = null)
    {
        return (Security::getCurrentUser() !== null);
    }
}
