import Distributed
import DistributedCluster

distributed actor Worker: DistributedWorker {

  distributed func submit(
    work: String
  ) async throws -> String {
    // work, work 👹
    try await Task.sleep(for: .seconds(1))
    self.actorSystem.log.info("Done \(work) for \(self.id)")
    return "Done"
  }
  
  init(actorSystem: ClusterSystem) async {
    self.actorSystem = actorSystem
    await actorSystem.receptionist.checkIn(self, with: .workers)
  }
}

extension DistributedReception.Key {
  static var workers: DistributedReception.Key<Worker> { "workers" }
}
