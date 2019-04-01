class WorkOrderFacade
  delegate :reference, :servitor_reference, :problem_description, :latest_appointment,
           :date_due, :repair_request, :property, :created, :dlo_status,
           :work_order_status, :notes, :appointments, :reports, to: :hackney

  def initialize(reference)
    @reference = reference
  end

  private

  def hackney
    @_hackney ||= Hackney::WorkOrder.find(@reference)
  end
end
