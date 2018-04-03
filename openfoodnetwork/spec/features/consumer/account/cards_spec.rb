require 'spec_helper'

feature "Credit Cards", js: true do
  include AuthenticationWorkflow
  describe "as a logged in user" do
    let(:user) { create(:user) }
    let!(:card) { create(:credit_card, user_id: user.id, gateway_customer_profile_id: 'cus_AZNMJ') }

    before do
      quick_login_as user

      allow(Stripe).to receive(:api_key) { "sk_test_xxxx" }
      allow(Stripe).to receive(:publishable_key) { "some_token" }
      Spree::Config.set(stripe_connect_enabled: true)

      stub_request(:get, "https://api.stripe.com/v1/customers/cus_AZNMJ").
        to_return(:status => 200, :body => JSON.generate(id: "cus_AZNMJ"))

      stub_request(:delete, "https://api.stripe.com/v1/customers/cus_AZNMJ").
        to_return(:status => 200, :body => JSON.generate(deleted: true, id: "cus_AZNMJ"))
    end

    it "lists saved cards, shows interface for adding new cards" do
      visit "/account"

      click_link I18n.t('spree.users.show.tabs.cards')

      expect(page).to have_content I18n.t(:saved_cards)

      within(".card#card#{card.id}") do
        expect(page).to have_content card.cc_type.capitalize
        expect(page).to have_content card.last_digits
      end

      # Shows the interface for adding a card
      click_button I18n.t(:add_a_card)
      expect(page).to have_field 'first_name'
      expect(page).to have_selector '#card-element.StripeElement'

      # Allows deletion of cards
      click_link I18n.t(:delete)

      expect(page).to have_content I18n.t(:card_has_been_removed, number: "x-#{card.last_digits}")
      expect(page).to have_content I18n.t(:you_have_no_saved_cards)
    end
  end
end
