class ContactMeMailer < ApplicationMailer
    #default to: 'raquel@fiarfli.art'

    def contact_email
        @email = params[:email]
        @subject = params[:subject]
        mail(
            to: "m@keays.io",
            from: @email, 
            subject: @subject, 
            body: params[:body]
        )
    end
end
