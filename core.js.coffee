###
# Simple module management
# http://github.com/wallin/core-js
#
# NO COPYRIGHTS OR LICENSES. DO WHAT YOU LIKE.
###

window.CORE = do () ->
  defer = (func) ->
    args = Array.prototype.slice.call(arguments, 1);
    return setTimeout ->
      return func.apply(func, args)
    , 0

  moduleData = {}
  debug = true
  eventTrace = []
  eventTraceFilter = null
  return {
    register: (moduleID, creator) ->
      if typeof(moduleID) == 'string' and typeof(creator) == 'function'
        return @log "Module '#{moduleID}' registration : FAILED : module already registered", 1 if moduleData[moduleID]
        temp = creator(new Sandbox(@, moduleID, true))
        if temp.init and typeof temp.init == 'function' and temp.destroy and typeof temp.destroy == 'function'
          temp = null
          moduleData[moduleID] =
            create: creator
            instance: null
        else
          @log "Module '#{moduleID}' registration : FAILED : 'init' or/and 'destroy' method missing", 1
      else
        @log "Module registration : FAILED : Invalid arguments", 1

    unregister: (moduleID) ->
      return unless moduleData[moduleID]
      @stop moduleID
      delete moduleData[moduleID]

    start: (moduleID, args...) ->
      mod = moduleData[moduleID]
      if mod
        mod.instance = mod.create(new Sandbox(@, moduleID))
        mod.events = mod.instance.events if mod.instance.events
        mod.instance.init(args...)
      else
        @log "Start module '#{moduleID}' : FAILED : no such module registered", 1
      return

    startAll: ->
      @start(i) for own i of moduleData
      return

    stop: (moduleID) ->
      data = moduleData[moduleID]
      if data.instance
        data.instance.destroy()
        data.instance = null
        delete data.events if data.events
      else
        @log "Stop module '#{moduleID}' : FAILED : no such active module", 1

    stopAll: ->
      @stop(i) for own i of moduleData
      return

    listen: (evts, moduleID) ->
      if evts and moduleID
        moduleData[moduleID].events = evts if moduleData[moduleID]
      else
        @log "Missing arguments to 'listen'", 1
    notify: (evt, args...) ->
      if debug and (not eventTraceFilter or evt.match(eventTraceFilter))
        d = new Date()
        time = d.toTimeString().split(' ')[0] + '.' + d.getMilliseconds()
        eventTrace.unshift [time, evt]
        eventTrace = eventTrace.slice(0, 35) if eventTrace.length > 35

      for own key, mod of moduleData
        defer mod.events[evt], args... if mod.events?[evt]
      return

    ignore: (evts, moduleId) ->
      mod = moduleData[moduleId]
      if mod?.instance?.events
        if evts then delete mod.instance.events[evts] else delete mod.instance.events
      return

    log: (message, severity = 1) ->
      console[if severity == 1 then 'log' else if severity == 2 then 'warn' else 'error'](message) if debug and console?.log
    debug: (state) -> debug = state
    trace: -> return eventTrace
    traceFilter: (regexp) -> eventTraceFilter = regexp
    dump: -> return @trace().join('\n')

  }

class window.Sandbox
  constructor: (@core, @moduleID, probe) ->
    return if probe
    @el = $("##{@moduleID}")
    @log "WARNING : No matching DOM element found for module", 2 unless @el.length > 0
  $: (selector) -> $(selector, @el)
  ajax: $.ajax
  notify: (evt, args...) -> @core.notify(evt, args...) if evt
  listen: (evts) -> @core.listen(evts, @moduleID) if evts
  ignore: (evts) -> @core.ignore(evts, @moduleID) if evts
  log: (message, severity) ->
    if typeof message == 'string'
      @core.log "#{@moduleID}: #{message}", severity
    else
      @core.log message, severity
