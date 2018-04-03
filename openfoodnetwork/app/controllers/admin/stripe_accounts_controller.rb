require 'stripe/account_connector'

module Admin
  class StripeAccountsController < BaseController
    protect_from_forgery except: :destroy_from_webhook

    def connect
      payload = params.slice(:enterprise_id)
      key = Openfoodnetwork::Application.config.secret_token
      url_params = { state: JWT.encode(payload, key, 'HS256'), scope: "read_write" }
      redirect_to Stripe::OAuth.authorize_url(url_params)
    end

    def connect_callback
      connector = Stripe::AccountConnector.new(spree_current_user, params)

      if connector.create_account
        flash[:success] = t('admin.controllers.enterprises.stripe_connect_success')
      elsif connector.connection_cancelled_by_user?
        flash[:notice] = t('admin.controllers.enterprises.stripe_connect_cancelled')
      else
        flash[:error] = t('admin.controllers.enterprises.stripe_connect_fail')
      end
      redirect_to main_app.edit_admin_enterprise_path(connector.enterprise, anchor: 'payment_methods')
    rescue Stripe::StripeError => e
      render text: e.message, status: 500
    end

    def destroy
      stripe_account = StripeAccount.find(params[:id])
      authorize! :destroy, stripe_account

      if stripe_account.deauthorize_and_destroy
        flash[:success] = "Stripe account disconnected."
      else
        flash[:error] = "Failed to disconnect Stripe."
      end

      redirect_to main_app.edit_admin_enterprise_path(stripe_account.enterprise)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Failed to disconnect Stripe."
      redirect_to spree.admin_path
    end

    def deauthorize
      # TODO is there a sensible way to confirm this webhook call is actually from Stripe?
      event = Stripe::Event.construct_from(params)
      return render nothing: true, status: 204 unless event.type == "account.application.deauthorized"

      destroyed = StripeAccount.where(stripe_user_id: event.account).destroy_all
      if destroyed.any?
        render text: "Account #{event.account} deauthorized", status: 200
      else
        render nothing: true, status: 204
      end
    end

    def status
      return render json: { status: :stripe_disabled } unless Spree::Config.stripe_connect_enabled
      stripe_account = StripeAccount.find_by_enterprise_id(params[:enterprise_id])
      return render json: { status: :account_missing } unless stripe_account
      authorize! :status, stripe_account

      begin
        status = Stripe::Account.retrieve(stripe_account.stripe_user_id)
        attrs = %i[id business_name charges_enabled]
        render json: status.to_hash.slice(*attrs).merge( status: :connected)
      rescue Stripe::APIError
        render json: { status: :access_revoked }
      end
    end
  end
end
