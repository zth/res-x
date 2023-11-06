let urls = ["/", "/start", "/user/1"]

Demo.server->StaticExporter.run(~urls)->Promise.done
