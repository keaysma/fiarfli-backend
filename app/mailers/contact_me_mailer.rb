class ContactMeMailer < ApplicationMailer
    default from: 'mailer@keays.io'
    default to: -> { ENV["EMAIL_RECEIVER"] }

    def contact_email
        @subject = params[:subject]
        mail(
            subject: "Contact Me: #{@subject}", 
            body: """
from: #{params[:name]} <#{params[:email]}>
subject: #{@subject}
message: #{params[:body]}
"""
        )
    end
end
