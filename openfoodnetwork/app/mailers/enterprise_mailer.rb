require 'devise/mailers/helpers'
class EnterpriseMailer < Spree::BaseMailer
  include Devise::Mailers::Helpers

  def welcome(enterprise)
    @enterprise = enterprise
    subject = t('enterprise_mailer.welcome.subject',
                enterprise: @enterprise.name,
                sitename: Spree::Config[:site_name])
    mail(:to => enterprise.email,
         :from => from_address,
         :subject => subject)
  end

  def confirmation_instructions(record, token)
    @token = token
    find_enterprise(record)
    subject = t('enterprise_mailer.confirmation_instructions.subject',
                enterprise: @enterprise.name)
    mail(to: (@enterprise.unconfirmed_email || @enterprise.email),
         from: from_address,
         subject: subject)
  end
  
  def claim_profile(enterprise, user, email)
    @enterprise = enterprise
    @user = user
    @address = Spree::Address::find(user.id)
    if (@address.firstname != nil && @address.lastname != nil)
      name = @address.firstname + " " + @address.lastname
    else
      name = user.login
    end
    
    @email = email
    if @email == nil || @email ==""
      @email = t('claim_email')
    end
    subject = t('email_claim_greeting',
                enterprise: @enterprise.name,
                user: name)
    body = t('email_claim_profile',
                enterprise: @enterprise.name,
                user: name)
    puts subject
    puts body
    mail(to: @email,
         from: t('claim_email'),
         subject: subject,
         body: body)         
  end
  def claim_profile_alert(enterprise, user, email)
    @enterprise = enterprise
    @user = user
    @address = Spree::Address::find(user.id)
    if (@address.firstname != nil && @address.lastname != nil)
      name = @address.firstname + " " + @address.lastname
    else
      name = user.login
    end
    
    @email = email
    if @email == nil || @email ==""
      @email = t('claim_email')
    end
    subject = t('email_claim_alert',
                enterprise: @enterprise.name,
                user: name)
    body = t('email_claim_alert_message',
                enterprise: @enterprise.name,
                user: name)
    puts subject
    puts body
    mail(to: t('claim_email'),
         from: t('claim_email'),
         subject: subject,
         body: body)         
  end
  private

  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
