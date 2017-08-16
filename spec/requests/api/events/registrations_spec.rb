# frozen_string_literal: true

require 'rails_helper'

describe Api::Events::RegistrationsController, type: :request do
  base_path = '/api/events/registrations'

  context 'not logged in' do
    it_behaves_like(
      'unauthorized',
      factory:   :registration,
      base_path:   base_path
    )
  end

  context 'is logged in and owns the event' do
    it_behaves_like(
      'resource_accessed_by_event_owner', {
        type: 'registrations',
        factory: :registration,
        base_path: base_path,
        event_relationship_name: :host
      }
    )
  end

  context 'is logged in but does not own the event' do
    it_behaves_like(
      'resource_accessed_by_random_user', {
        type: 'registrations',
        factory: :registration,
        base_path: base_path,
        event_relationship_name: :host
      }
    )
  end

  context 'is logged in and the user is a collaborator' do
    it_behaves_like(
      'resource_accessed_by_collaborator_with_full_access', {
        type: 'registrations',
        factory: :registration,
        base_path: base_path,
        event_relationship_name: :host
      }
    )
  end
end