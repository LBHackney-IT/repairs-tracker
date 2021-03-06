class Hackney::WorkOrder
  include ActiveModel::Model

  attr_accessor :reference, :rq_ref, :prop_ref, :created, :date_due,
                :work_order_status, :dlo_status, :servitor_reference,
                :problem_description, :trade

  def self.find(reference)
    response = HackneyAPI::RepairsClient.new.get_work_order(reference)
    build(response)
  end

  def self.find_all(references)
    if references.any?
      response = HackneyAPI::RepairsClient.new.get_work_orders_by_references(references)
      response.map { |r| build(r) }
    else
      []
    end
  rescue HackneyAPI::RepairsClient::RecordNotFoundError => e
    Rails.logger.error(e)
    Appsignal.set_error(e, message: "Work order(s) not found")
    []
  end

  def self.feed(previous_reference)
    response = HackneyAPI::RepairsClient.new.work_order_feed(previous_reference)
    response.map { |hash| build(hash) }
  end

  def self.for_property(property_references:, date_from:, date_to:)
    HackneyAPI::RepairsClient.new.get_work_orders_by_property(
      references: property_references,
      date_from: date_from,
      date_to: date_to
    ).map do |attributes|
      build(attributes)
    end
  end

  def self.build(attributes)
    new(
      reference: attributes['workOrderReference'].strip,
      rq_ref: attributes['repairRequestReference']&.strip,
      prop_ref: attributes['propertyReference'].strip,
      created: attributes['created'].to_datetime,
      date_due: attributes['dateDue']&.to_datetime,
      work_order_status: attributes['workOrderStatus']&.strip,
      dlo_status: attributes['dloStatus']&.strip,
      servitor_reference: attributes['servitorReference']&.strip,
      problem_description: attributes['problemDescription'],
      trade: attributes['trade']
    )
  end

  def repair_request
    @_repair_request ||= Hackney::RepairRequest.find(rq_ref)
  rescue HackneyAPI::RepairsClient::HackneyApiError => e
    Rails.logger.error(e)
    Appsignal.set_error(e, message: "Repair request not found for this work order")
    @_repair_request = Hackney::RepairRequest::NULL_OBJECT
  end

  def property
    @_property ||= Hackney::Property.find(prop_ref)
  end

  def appointments
    @_appointments ||= Hackney::Appointment.all_for_work_order(reference)
  end
end
