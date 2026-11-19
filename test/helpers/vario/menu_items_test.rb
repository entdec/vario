# frozen_string_literal: true

require 'test_helper'

module Vario
  class MenuItemsTest < ActionView::TestCase
    # Menus::Builder's menu, as far as vario_menu_items uses it
    Menu = Struct.new(:items) do
      def item(id, **options)
        items << [id, options]
      end
    end

    setup do
      @account = accounts(:boxture)
      @menu = Menu.new([])
      Object.const_set(:GeneralSettingsPolicy, Class.new(TopicPolicy) { def show? = false })
    end

    teardown do
      Object.send(:remove_const, :GeneralSettingsPolicy)
    end

    test 'an item per topic it may see, linked to its page, with its settings as keywords' do
      view.vario_menu_items(@menu, @account)

      assert_equal %i[vario_examples vario_print_node], @menu.items.map(&:first).sort
      id, options = @menu.items.find { |item_id, _options| item_id == :vario_examples }
      assert_equal :vario_examples, id
      assert_equal 'Examples', options[:label]
      assert_equal 'fal fa-flask', options[:icon]
      assert_equal '/settings/topics/examples', options[:link]
      assert_includes options[:link_attributes][:data][:keywords], 'Working days'
    end

    test "the current settable's, without one nothing" do
      current_settable = Vario.config.instance_variable_get(:@current_settable)
      Vario.config.current_settable = @account
      view.vario_menu_items(@menu)
      assert_equal 2, @menu.items.size

      Vario.config.current_settable = nil
      assert_nil view.vario_menu_items(Menu.new([]))
    ensure
      Vario.config.current_settable = current_settable
    end
  end
end
