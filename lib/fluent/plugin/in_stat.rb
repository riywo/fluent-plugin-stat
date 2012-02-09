module Fluent

  class StatInput < Input
    Plugin.register_input('stat', self)

    def initialize
      super
      @hostname = `hostname -s`.chomp!
      $:.unshift File.dirname(__FILE__)
      require 'stat'
    end

    config_param :add_prefix, :string
    config_param :interval, :time

    def configure(conf)
      super
    end

    def start
      super
      
      @thread = Thread.new(&method(:run))
    end

    def run
      stat = Stat.new
      @running = true
      while @running
        result = stat.calc_difference(@interval)
        logs = Hash.new
        result.each { |k1, v1|
          if k1 == :mem
            logs[k1.to_s] = v1
          else
            v1.each { |k2, v2|
              if k1 == :cpu and k2 == :cpu
                logs[k2.to_s] = v2
              else
                logs[k1.to_s+'.'+k2.to_s] = v2
              end
            }
          end
        }
        logs.each { |tag, record|
          Engine.emit(@add_prefix+'.'+tag, Engine.now, record)
        }
      end      
    end

    def shutdown
      @running = false
      @thread.join
    end
  end

end
