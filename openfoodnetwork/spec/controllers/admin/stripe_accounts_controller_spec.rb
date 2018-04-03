require 'spec_helper'

describe Admin::StripeAccountsController, type: :controller do
  let(:enterprise) { create(:distributor_enterprise) }

  before do
    allow(Stripe).to receive(:client_id) { "some_id" }
  end

  describe "#connect" do
    before do
      allow(controller).to receive(:spree_current_user) { enterprise.owner }
    end

    it "redirects to Stripe Authorization url constructed OAuth" do
      spree_get :connect
      expect(response.location).to match %r(\Ahttps://connect.stripe.com)
      uri = URI.parse(response.location)
      params = CGI.parse(uri.query)
      expect(params.keys).to include 'client_id', 'response_type', 'state', 'scope'
    end
  end

  context "#connect_callback" do
    let(:params) { { id: enterprise.permalink } }
    let(:connector) { double(:connector) }

    before do
      allow(controller).to receive(:spree_current_user) { enterprise.owner }
      allow(Stripe::AccountConnector).to receive(:new) { connector }
    end

    context "when the connector.create_account raises a StripeError" do
      before do
        allow(connector).to receive(:create_account).and_raise Stripe::StripeError, "some error"
      end

      it "returns a 500 error" do
        spree_get :connect_callback, params
        expect(response.status).to be 500
      end
    end

    context "when the connector.create_account raises an AccessDenied error" do
      before do
        allow(connector).to receive(:create_account).and_raise CanCan::AccessDenied, "some error"
      end

      it "redirects to unauthorized" do
        spree_get :connect_callback, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "when the connector fails in creating a new stripe account record" do
      before { allow(connector).to receive(:create_account) { false } }

      context "when the user cancelled the connection" do
        before { allow(connector).to receive(:connection_cancelled_by_user?) { true } }

        it "renders a failure message" do
          allow(connector).to receive(:enterprise) { enterprise }
          spree_get :connect_callback, params
          expect(flash[:notice]).to eq I18n.t('admin.controllers.enterprises.stripe_connect_cancelled')
          expect(response).to redirect_to edit_admin_enterprise_path(enterprise, anchor: 'payment_methods')
        end
      end

      context "when some other error caused the failure" do
        before { allow(connector).to receive(:connection_cancelled_by_user?) { false } }

        it "renders a failure message" do
          allow(connector).to receive(:enterprise) { enterprise }
          spree_get :connect_callback, params
          expect(flash[:error]).to eq I18n.t('admin.controllers.enterprises.stripe_connect_fail')
          expect(response).to redirect_to edit_admin_enterprise_path(enterprise, anchor: 'payment_methods')
        end
      end
    end

    context "when the connector succeeds in creating a new stripe account record" do
      before { allow(connector).to receive(:create_account) { true } }

      it "redirects to the enterprise edit path" do
        allow(connector).to receive(:enterprise) { enterprise }
        spree_get :connect_callback, params
        expect(flash[:success]).to eq I18n.t('admin.controllers.enterprises.stripe_connect_success')
        expect(response).to redirect_to edit_admin_enterprise_path(enterprise, anchor: 'payment_methods')
      end
    end
  end

  describe "#deauthorize" do
    let!(:stripe_account) { create(:stripe_account, stripe_user_id: "webhook_id") }
    let(:params) do
      {
        "format" => "json",
        "id" => "evt_123",
        "object" => "event",
        "data" => { "object" => { "id" => "ca_9B" } },
        "type" => "account.application.deauthorized",
        "account" => "webhook_id"
      }
    end

    it "deletes Stripe accounts in response to a webhook" do
      post 'deauthorize', params
      expect(response.status).to eq 200
      expect(response.body).to eq "Account webhook_id deauthorized"
      expect(StripeAccount.all).not_to include stripe_account
    end

    context "when the stripe_account id on the event does not match any known accounts" do
      before do
        params["account"] = "webhook_id1"
      end

      it "does nothing" do
        post 'deauthorize', params
        expect(response.status).to eq 204
        expect(StripeAccount.all).to include stripe_account
      end
    end

    context "when the event is not a deauthorize event" do
      before do
        params["type"] = "account.application.authorized"
      end

      it "does nothing" do
        post 'deauthorize', params
        expect(response.status).to eq 204
        expect(StripeAccount.all).to include stripe_account
      end
    end
  end

  describe "#destroy" do
    let(:params) { { format: :json, id: "some_id" } }

    context "when the specified stripe account doesn't exist" do
      it "raises an error?" do
        spree_delete :destroy, params
      end
    end

    context "when the specified stripe account exists" do
      let(:stripe_account) { create(:stripe_account, enterprise: enterprise) }

      before do
        # So that we can stub #deauthorize_and_destroy
        allow(StripeAccount).to receive(:find) { stripe_account }
        params[:id] = stripe_account.id
      end

      context "when I don't manage the enterprise linked to the stripe account" do
        let(:some_user) { create(:user) }

        before { allow(controller).to receive(:spree_current_user) { some_user } }

        it "redirects to unauthorized" do
          spree_delete :destroy, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "when I manage the enterprise linked to the stripe account" do
        before { allow(controller).to receive(:spree_current_user) { enterprise.owner } }

        context "and the attempt to deauthorize_and_destroy succeeds" do
          before { allow(stripe_account).to receive(:deauthorize_and_destroy) { stripe_account } }

          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to edit_admin_enterprise_path(enterprise)
            expect(flash[:success]).to eq "Stripe account disconnected."
          end
        end

        context "and the attempt to deauthorize_and_destroy fails" do
          before { allow(stripe_account).to receive(:deauthorize_and_destroy) { false } }

          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to edit_admin_enterprise_path(enterprise)
            expect(flash[:error]).to eq "Failed to disconnect Stripe."
          end
        end
      end
    end
  end

  describe "#status" do
    let(:params) { { format: :json } }

    before do
      allow(Stripe).to receive(:api_key) { "sk_test_12345" }
      Spree::Config.set(stripe_connect_enabled: false)
    end

    context "when Stripe is not enabled" do
      it "returns with a status of 'stripe_disabled'" do
        spree_get :status, params
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq "stripe_disabled"
      end
    end

    context "when Stripe is enabled" do
      before { Spree::Config.set(stripe_connect_enabled: true) }

      context "but no stripe account is associated with the specified enterprise" do
        it "returns with a status of 'account_missing'" do
          spree_get :status, params
          json_response = JSON.parse(response.body)
          expect(json_response["status"]).to eq "account_missing"
        end
      end

      context "and a stripe account is associated with the specified enterprise" do
        let!(:account) { create(:stripe_account, stripe_user_id: "acc_123", enterprise: enterprise) }

        context "but I don't manage the enterprise" do
          let(:user) { create(:user) }
          let(:enterprise2) { create(:enterprise) }
          before do
            user.owned_enterprises << enterprise2
            params[:enterprise_id] = enterprise.id
            allow(controller).to receive(:spree_current_user) { user }
          end

          it "redirects to unauthorized" do
            spree_get :status, params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "and I manage the enterprise" do
          before do
            params[:enterprise_id] = enterprise.id
            allow(controller).to receive(:spree_current_user) { enterprise.owner }
          end

          context "but access has been revoked or does not exist on stripe's servers" do
            before do
              stub_request(:get, "https://api.stripe.com/v1/accounts/acc_123").to_return(status: 404)
            end

            it "returns with a status of 'access_revoked'" do
              spree_get :status, params
              json_response = JSON.parse(response.body)
              expect(json_response["status"]).to eq "access_revoked"
            end
          end

          context "which is connected" do
            let(:stripe_account_mock) do
              {
                id: "acc_123",
                business_name: "My Org",
                charges_enabled: true,
                some_other_attr: "something"
              }
            end

            before do
              stub_request(:get, "https://api.stripe.com/v1/accounts/acc_123").to_return(body: JSON.generate(stripe_account_mock))
            end

            it "returns with a status of 'connected'" do
              spree_get :status, params
              json_response = JSON.parse(response.body)
              expect(json_response["status"]).to eq "connected"
              # serializes required attrs
              expect(json_response["business_name"]).to eq "My Org"
              # ignores other attrs
              expect(json_response["some_other_attr"]).to be nil
            end
          end
        end
      end
    end
  end
end
