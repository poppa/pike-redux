//! Implements @[Redux.Action]
private class action(string type, int payload) {
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

  Redux.Action inc_delayed(int payload) {
    return lambda (function dispatch) {
      werror("\n  *** Dispatcher wait 3 sec ***\n\n");
      call_out(lambda () {
        return dispatch(action(INC, payload));
      }, 3);
    };
  }
}

Redux.State reducer(Redux.State state, Redux.Action action)
{
  if (action->type == Redux.ActionType.INIT) {
    return Redux.State(([]));
  }

  switch (action->type)
  {
    case my_actions.INC:
      state = state + ([ "val": state["val"] + action->payload ]);
      break;

    case my_actions.DEC:
      state = state + ([ "val": state["val"] - action->payload ]);
      break;
  }

  return state;
}

function interceptor(mapping(string:function) a) {
  function get_state = a->get_state;
  return lambda (function next) {
    return lambda (mixed action) {
      werror("||| Interceptor %O > %O |||\n", action, get_state()["val"]);
      return next(action);
    };
  };
}

int main(int argc, array(string) argv)
{
  function middleware = Redux.apply_middleware(Redux.thunk, interceptor);
  Redux.Store store = Redux.create_store(reducer, 0, middleware);

  store->subscribe(lambda (Redux.Action a) {
    werror(">>> Subscription: %O\n", a);
    if (store->get_state()["val"] == 8) {
      werror("Ok, we're done\n");
      exit(0);
    }
  });

  mapping(string:function) actions =
    Redux.bind_action_creators(my_actions, store->dispatch);

  actions->inc(12);
  actions->inc_delayed(3);
  actions->dec(7);


  return -1;
}
