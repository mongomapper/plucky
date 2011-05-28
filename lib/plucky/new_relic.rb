if defined?(NewRelic)
  Plucky::Query.class_eval do
    include NewRelic::Agent::MethodTracer

    Plucky::Methods.each do |method_name|
      add_method_tracer(method_name.to_sym)
    end
  end
end