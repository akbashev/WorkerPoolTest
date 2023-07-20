import Distributed
import DistributedCluster

distributed actor Master {
  
  let workerPool: DistributedCluster.WorkerPool<Worker>
  /**
   If you change this to custom implemented WorkerPool—everything will work.
   */
//   let workerPool: WorkerPool
  
  distributed func work() async throws {
    /**
     DistributedCluster's WorkerPool will go into loop and terminate all workers here.
     */
    try? await self.workerPool.submit(work: "check")
    try await Task.sleep(for: .seconds(1))
    try await self.work()
  }
  
  init(actorSystem: ClusterSystem) async throws {
    self.actorSystem = actorSystem
    self.workerPool = try await .init(
      selector: .dynamic(.workers),
      actorSystem: actorSystem
    )
//    self.workerPool = await .init(
//      actorSystem: actorSystem
//    )
  }
}

