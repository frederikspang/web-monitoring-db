require 'test_helper'

class Api::V0::AnnotationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'can annotate a version' do
    page = pages(:home_page)
    annotation = { 'test_key' => 'test_value' }

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: annotation
    )

    assert_response :success
    assert_equal 'application/json', @response.content_type
    body = JSON.parse @response.body
    assert body.key?('links'), 'Response should have a "links" property'
    assert body.key?('data'), 'Response should have a "data" property'
    assert_equal annotation, body['data']['annotation']
  end

  test 'posting a new annotation updates previous annotations by the same user' do
    page = pages(:home_page)
    annotation1 = { 'test_key' => 'test_value' }
    annotation2 = { 'test_key' => 'new_value' }

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: annotation1
    )
    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: annotation2
    )
    get(api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"))

    assert_response :success
    body = JSON.parse @response.body
    assert_equal 1, body['data'].length, 'Multiple annotations were created'
    assert_equal annotation2, body['data'][0]['annotation']
  end

  test 'multiple users can annotate a change' do
    page = pages(:home_page)
    annotation1 = { 'test_key' => 'test_value' }
    annotation2 = { 'test_key' => 'new_value' }

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: annotation1
    )

    sign_in users(:admin_user)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: annotation2
    )

    get(api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"))

    assert_response :success
    body = JSON.parse @response.body
    assert_equal 2, body['data'].length, 'Two annotations were not created'
  end

  test 'annotations with the `priority` property update change priority' do
    change = changes(:page1_change_1_2)

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(
        change.version.page,
        "#{change.from_version.uuid}..#{change.version.uuid}"
      ),
      as: :json,
      params: { 'priority' => 1.0 }
    )

    change.reload
    assert_response :success
    assert_equal(1, change.priority, 'Change#priority was not updated by annotation')
  end

  test 'annotations with the `significance` property update change priority' do
    change = changes(:page1_change_1_2)

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(
        change.version.page,
        "#{change.from_version.uuid}..#{change.version.uuid}"
      ),
      as: :json,
      params: { 'significance' => 1.0 }
    )

    change.reload
    assert_response :success
    assert_equal(1, change.significance, 'Change#significance was not updated by annotation')
  end

  test 'it rejects annotations with the `priority` not between 0 and 1' do
    page = pages(:home_page)

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: { 'priority' => 1.1 }
    )
    assert_response :unprocessable_entity
    assert_not_equal(
      1.1,
      page.versions[0].change_from_previous.priority,
      'Change#priority was updated by annotation'
    )

    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: { 'priority' => -1 }
    )
    assert_response :unprocessable_entity
    assert_not_equal(
      -1,
      page.versions[0].change_from_previous.priority,
      'Change#priority was updated by annotation'
    )
  end

  test 'it rejects annotations with the `significance` not between 0 and 1' do
    page = pages(:home_page)

    sign_in users(:alice)
    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: { 'significance' => 1.1 }
    )
    assert_response :unprocessable_entity
    assert_not_equal(
      1.1,
      page.versions[0].change_from_previous.priority,
      'Change#significance was updated by annotation'
    )

    post(
      api_v0_page_change_annotations_path(page, "..#{page.versions[0].uuid}"),
      as: :json,
      params: { 'significance' => -1 }
    )
    assert_response :unprocessable_entity
    assert_not_equal(
      -1,
      page.versions[0].change_from_previous.priority,
      'Change#significance was updated by annotation'
    )
  end
end
