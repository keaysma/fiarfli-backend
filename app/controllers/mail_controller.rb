class MailController < ApiController
    def create
        ContactMeMailer.with(email: "m@keays.io", subject: "test subject", content: "test content", body: "ooOOGABJABOOGA").contact_email.deliver_now
        render json: {
            message: "success!"
        }
    end
end