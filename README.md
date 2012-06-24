# Core JS module management
My take on the sandbox/module-pattern.

*TODO*: Add more documentation

## Example

    CORE.register 'myModule', (m) ->
      return {
        init:    -> alert 'Started!'
        destroy: -> alert 'Stopped!'
        events:
          'button:clicked': -> alert 'Someone clicked button!'
      }

    CORE.startAll()
