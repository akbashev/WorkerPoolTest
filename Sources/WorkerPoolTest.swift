import Distributed
import DistributedCluster

typealias DefaultDistributedActorSystem = ClusterSystem

@main
public struct WorkerPoolTest {
  public static func main() async throws {
    let master = await ClusterSystem("master")
    let worker = await ClusterSystem("worker") { settings in
      settings.bindPort = 1111
    }
    
    worker.cluster.join(endpoint: master.settings.endpoint)
    
    try await ensureCluster([master, worker], within: .seconds(10))
    
    worker.log.info("Joined?")
    
    let masterActor = try await Master(
      actorSystem: master
    )
    
    // non-structured not to wait
    Task {
      try await masterActor.work()
    }
    
    var workers: [Worker] = []
    for _ in 0..<9 {
      await workers.append(Worker(actorSystem: worker))
    }
    
    try await master.terminated
  }
  
  private static func ensureCluster(_ systems: [ClusterSystem], within: Duration) async throws {
    let nodes = Set(systems.map(\.settings.bindNode))
    
    try await withThrowingTaskGroup(of: Void.self) { group in
      for system in systems {
        group.addTask {
          try await system.cluster.waitFor(nodes, .up, within: within)
        }
      }
      // loop explicitly to propagagte any error that might have been thrown
      for try await _ in group {
        
      }
    }
  }
}
