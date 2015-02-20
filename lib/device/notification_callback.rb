class Device
  class NotificationCallback
    attr_reader :on, :before, :after, :description
    attr_accessor :results

    CallbackResult = Struct.new(:before_execute, :result, :after_execute)

    def initialize(description, procs = {})
      @description = description
      @on          = procs[:on]
      @before      = procs[:before]
      @after       = procs[:after]
      @results     = {:on => [], :before => [], :after => []}
      schedule!
    end

    def schedule!
      Notification.schedule(self)
    end

    def call(event, moment = :on)
      if support?(moment)
        results[moment] << CallbackResult.new(
          Time.now,
          perform(event, moment),
          Time.now
        )
      end
    end

    private
    def perform
      unless equal_arity?(event, moment)
        return "Error Arity not Match: Event arity #{event.parameters.size} Proc arity #{send(moment).arity}"
      end
      self.send(moment).call(*event.parameters)
    end

    def support?(moment)
      ! send(moment).nil?
    end

    def equal_arity?(event, moment)
      on.arity != event.parameters.size
    end
  end
end
