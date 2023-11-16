let urls = ["/", "/start", "/user/1"]

Demo.server
->ResX.StaticExporter.run(~urls)
->Promise.done
