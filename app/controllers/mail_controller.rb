class MailController < ApiController
    def create
        @input = params[:mail]
        @missing_keys = [
            :email, :name, :subject, :body,
        ].filter! { |key| !params.key? key }
        if @missing_keys.length > 0 then
            render json: {
                message: "error",
                input: @input,
                required: @missing_keys
            }
            return
        end
        ContactMeMailer.with(
            email: params[:email], 
            name: params[:name],
            subject: params[:subject], 
            body: params[:body]
        ).contact_email.deliver_now
        render json: {
            message: "success",
            input: @input
        }
    end
end