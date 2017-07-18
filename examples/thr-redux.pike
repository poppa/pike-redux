/*

  This is just a prototype

*/

#define RND_SLEEP() sleep(random(1.0)+0.01)

Redux.Store store;
function unsubscriber;

class MyAction(string type, int payload) {}

int main(int argc, array(string) argv)
{
  store = Redux.create_store(reducer);
  unsubscriber = store->subscribe(subscriber);

  main2();

  werror("All done\n");

  call_out(lambda () {
    store = 0;
    call_out(exit, .2, 0);
  }, 1);

  return -1;
}

void main2()
{
  object backend = thread_create(lambda () {
    ({
      thread_create(run, "left", "inc"),
      thread_create(run, "right", "dec")
    })->wait();
  });

  backend->wait();
}

void run(string name, string type)
{
  werror(">>>> run(%O, %O)\n", name, type);

  store->subscribe(lambda () {
    werror("    [%s] called, State value: %O\n", name, store->get_state()["value"]);
  });

  int iters = 15;

  RND_SLEEP();

  for (int i = 1; i <= iters; i++) {
    store->dispatch(MyAction(type, i));
    RND_SLEEP();
  }
}

void subscriber(Redux.Action a)
{
  werror("    [none] called, State value: %O\n", store->get_state()["value"]);

  if (store->get_state()["value"] == 0) {
    werror("      -- unsubscribing generic subscriber --\n");
    unsubscriber();
  }
}

Redux.State reducer(Redux.State state, MyAction action)
{
  // werror("Reducer called: %O : %O\n", state->value, action->type);

  switch (action->type)
  {
    case Redux.ActionType.INIT:
      werror("!!! GOT INIT STATE !!!\n");
      return Redux.State(([]));

    case "inc":
      werror("+++ inc: %O\n", action->payload);
      state = state + ([ "value" : state["value"] + action->payload ]);
      break;

    case "dec":
      // RND_SLEEP();
      werror("--- dec: %O\n", action->payload);
      state = state + ([ "value" : state["value"] - action->payload ]);
      break;
  }

  return state;
}
