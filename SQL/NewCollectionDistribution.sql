System.Data.SqlClient.SqlException (0x80131904): The operation could not be performed because OLE DB provider "SQLNCLI11" for linked server "BOR-MANGO-DB" was unable to begin a distributed transaction.
   at System.Data.SqlClient.SqlCommand.<>c.<ExecuteDbDataReaderAsync>b__174_0(Task`1 result)
   at System.Threading.Tasks.ContinuationResultTaskFromResultTask`2.InnerInvoke()
   at System.Threading.Tasks.Task.Execute()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at System.Data.Entity.Core.Objects.ObjectContext.<ExecuteStoreQueryInternalAsync>d__73`1.MoveNext()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at System.Data.Entity.Utilities.TaskExtensions.CultureAwaiter`1.GetResult()
   at System.Data.Entity.Core.Objects.ObjectContext.<ExecuteInTransactionAsync>d__3d`1.MoveNext()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at System.Data.Entity.SqlServer.DefaultSqlExecutionStrategy.<ExecuteAsyncImplementation>d__9`1.MoveNext()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at System.Data.Entity.Utilities.TaskExtensions.CultureAwaiter`1.GetResult()
   at System.Data.Entity.Core.Objects.ObjectContext.<ExecuteStoreQueryReliablyAsync>d__70`1.MoveNext()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at System.Data.Entity.Utilities.TaskExtensions.CultureAwaiter`1.GetResult()
   at System.Data.Entity.Internal.LazyAsyncEnumerator`1.<FirstMoveNextAsync>d__0.MoveNext()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at System.Data.Entity.Infrastructure.IDbAsyncEnumerableExtensions.<SingleOrDefaultAsync>d__38`1.MoveNext()
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Col.Domain.Handlers.FillScoreDataHandler.<Run>d__5.MoveNext() in D:\BuildAgent\work\8c294c729fde2fe8\src\Col\Col.Domain\Handlers\FillScoreDataHandler.cs:line 54
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Col.Domain.Handlers.BaseStepHandler`1.<Invoke>d__4.MoveNext() in D:\BuildAgent\work\8c294c729fde2fe8\src\Col\Col.Domain\Handlers\BaseStepHandler.cs:line 31
ClientConnectionId:eeb59c2b-14a5-4504-9446-07b76c1dfdc3
Error Number:7391,State:2,Class:16