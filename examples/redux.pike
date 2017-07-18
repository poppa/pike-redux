
class action(string type, int payload) {
  string _sprintf(int t) {
    return sprintf("%O(%O => %O)", object_program(this), type, payload);
  }
}

class my_actions {
  constant INC = "inc";
  constant DEC = "dec";

  Redux.Action inc(int payload) {
    return action(INC, payload);
  }

  Redux.Action dec(int payload) {
    return action(DEC, payload);
  }
}

Redux.Store store;
mapping actions;

Redux.State reducer(Redux.State state, Redux.Action action)
{
  if (action->type == Redux.ActionType.INIT) {
    return Redux.State(([ "val" : 0 ]));
  }

  switch (action->type)
  {
    case "inc":
      state = state + ([ "val" : state->val + action->payload ]);
      break;

    case "dec":
      state = state + ([ "val" : state->val - action->payload ]);
      break;
  }

  return state;
}


int main(int argc, array(string) argv)
{
  store = Redux.create_store(reducer);
  actions = Redux.bind_action_creators(my_actions, store->dispatch);

  function unsubscribe =
    store->subscribe(lambda (Redux.Action a) {
      werror(">>> Subscriber called: %O\n", a);
    });

  actions->inc(12);
  actions->dec(7);
  unsubscribe();
  actions->inc(3);

  werror("Result: %O\n", store->get_state()["val"]);

  return 0;
}
