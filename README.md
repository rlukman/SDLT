# NZTA Security Development Lifecycle Tool
The SDLT is a digital Questionnaire and Task management system for walking technology deliverables through Security Assurance.

A user of the SDLT can answer a series of questions about their product deliverable. The SDLT will create and manage the necessary security assurance tasks (e.g. PCI-DSS compliance, penetration test, information classification). Once the user has completed the tasks, the SDLT will handle the approvals for the submission by having security architects, chief information security officer and business owner approve it digitally.

## Installation
This assumes all PHP requirements are met, Apache is configured with rewrite rules and `AllowOverride All` set, and has a virtualhost pointing at `/path/to/sdlt/public`. See SilverStripe installation instructions for more information

1. Clone the repository using Git clone to /path/to/sdlt
2. Run `composer install`
3. Run `vendor/bin/sake dev/build flush=` on the terminal
4. You will need to copy the .env.example to a .env file and replace the values with your own. The user defined on SS_DATABASE_USER will need to have high enough privileges to create a database

## Configuration and Personalisation

* Update your auth.yml
    * `Bigfork\SilverStripeOAuth\Client\Authenticator\Authenticator.providers.ActiveDirectory.name: YourName`
* update app/lang/en.yml with your own values
* Update `NZTA/SDLT/forms/FormAction_OAuth_ActiveDirectory.ss` with your own agency's login name

### Azure Active Directory
This website uses Azure Active Directory to authenticate. At the moment this is required to use the application but we are working to make it optional.

Azure supports OAuth,  so we use the oauth-login module to authenticate.

You need to add some values to your .env (or SetEnv) for this to work. Follow 
these instructions to obtain these values from Azure active directory:
https://www.symbiote.com.au/blog/azure-active-directory-and-silverstripe/

```
# Taken from the "Application ID" ; Azure AD => App Registrations => {App}
AZURE_CLIENT_ID="..."

# Create from Azure AD => App registrations => {App} => Settings => Keys
AZURE_CLIENT_SECRET="..."

# From Azure AD => Properties => Directory ID
AZURE_TENANT_ID="..."
```

SDLT does not take the traditional SAML + LDAP approach that older Active Directory integrations used. As of 2016, Microsoft's Azure cloud provider allows for managed Active Directory instances and connecting via OAuth2. This enables SilverStripe to authenticate users in the same way that Google, Facebook, and thousands of other identity providers handle online authentications against their service. 

The primary means of connecting to SDLT is through Active Directory, which means the default authenticator has been disabled by default. In case of a lockout, or when support staff needs to access the CMS, the default authenticator can be accessed by appending ?showloginform=1 to the /admin URL. You can use this mechanism to login if a Default Admin account is enabled through the codebase.

A default set of questionnaires, tasks, pillars, questions, and answers has been created and distributed in CSV format. You can use this to populate your database as a starting point, then tailor the existing set for your own needs.  Run `vendor/bin/sake dev/tasks/NZTA-SDLT-Tasks-SetupSDLTDataTask` if you want to use this data. Note that this set of information does _not_ include questionnaire emails, which need to be set up for each installation.

#### Adding new administrators setup
All users that are intended to use this system must first log into SilverStripe via AD so that SilverStripe can automatically create an account for them. On their first successful login, a Member account containing their first name, surname, email address, and unique Member Identifier will be created in the Security section of the CMS. This account *will not*, and *must not*, have any privileges until an existing Administrator adds them to the appropriate group. Attempts to create the accounts beforehand will result in an error. Once a group is assigned, these users will be able to log in with their Active Directory accounts.
