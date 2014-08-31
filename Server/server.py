from twisted.internet.protocol import Factory, Protocol
from twisted.internet import reactor

class IphoneChat(Protocol):
     def connectionMade(self):
        self.factory.clients.append(self)
        print "clients are ", self.factory.clients

     def connectionLost(self, reason):
        self.factory.clients.remove(self)
        print "clients are ", self.factory.clients

     def dataReceived(self, data):
        a = data.strip().split(":")
        print a
        if len(a) > 1:
            command = a[0]
            content = a[1]
            ok = 0;
            msg = ""
            if command == "iam":
                self.name = content
                msg = self.name + " has joined"
                ok = 1;
 
            elif command == "msg":
                msg = self.name + ": " + content
                print msg
                ok = 1;
 
            if (ok == 0):
                print "Error in command"
                return

            for c in self.factory.clients:
                c.message(msg)


     def message(self, message):
        self.transport.write(message + '\n')

factory = Factory()
factory.clients = []
factory.protocol = IphoneChat
reactor.listenTCP(90, factory)
print "Iphone Chat server started"
reactor.run()