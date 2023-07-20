import Distributed
import DistributedCluster

/// Custom implemented worker pool just to double check logic is working.
distributed actor WorkerPool: LifecycleWatch {
  
  struct WorkerError: Error {}

  private var workers: Set<Worker> = []
  
  var listingTask: Task<Void, Never>?
  
  init(actorSystem: ActorSystem) async {
    self.actorSystem = actorSystem
    
    listingTask = Task<Void, Never> {
      for await worker in await actorSystem.receptionist.listing(of: .workers) {
        self.workers.insert(worker)
        self.actorSystem.log.info("Worker \(worker.id) available.")
        
        self.watchTermination(of: worker)
      }
    }
  }
  
  deinit {
    listingTask?.cancel()
  }
  
  distributed func submit(work item: String) async throws -> String {
    guard let worker = workers.shuffled().first else {
      actorSystem.log.error("No workers to submit job to. Workers: \(workers)")
      throw WorkerError()
    }
    return try await worker.submit(work: item)
  }

  func terminated(actor id: ActorID) async {
    actorSystem.log.info("Removing terminated actor \(id)")
    guard let member = workers.first(where: { $0.id == id }) else { return }
    workers.remove(member)
  }
}
