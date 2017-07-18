import ".";

protected Reducer reducer;
protected State current_state;

private array(Subscriber) subscribers;
private array(Subscriber) next_subscribers;

//! To prevent recursive calls to dispatch from reducers
private bool is_dispatching;

public State `state() { return current_state; }

public function(Action : Action) dispatch;

//! Same as @[state] but more readable when used as function pointer in APIs.
//! Consider internal, use @[Redux.Store->state] instead.
public State get_state()
{
  return current_state;
}

protected void create(Reducer reducer, State state)
{
  this::reducer = reducer;
  this::current_state = state;
  next_subscribers = subscribers = ({});

  dispatch = low_dispatch;

  dispatch(Action(ActionType.INIT));
}

//! If @[next_subscribers] and @[subscribers] hold the same reference,
//! @[next_subscribers] will get a copy of @[subscribers].
private void ensure_can_mutate_listeners()
{
  if (next_subscribers == subscribers) {
    next_subscribers = subscribers + ({});
  }
}


public void replace_reducer(Reducer reducer)
{
  this::reducer = reducer;
}


public Subscriber subscribe(Subscriber s)
{
  ensure_can_mutate_listeners();
  next_subscribers += ({ s });
  return s;
}


public void unsubscribe(Subscriber s)
{
  if (!has_value(subscribers, s)) {
    return;
  }

  ensure_can_mutate_listeners();
  next_subscribers -= ({ s });
}

//! @ignore
//! This is internal methods
array(Subscriber) __get_subscribers() {
  return next_subscribers + ({});
}
//! @endignore

public Action low_dispatch(Action action)
{
  // if (__new_dispatcher) {
  //   // werror("HAVE NEW DISPATCHER: %O\n", new_dispatcher);
  //   // Action new_action = new_dispatcher(action);
  //   // new_dispatcher = 0;
  //   return __new_dispatcher(action);
  // }

  if (!action) {
    error("Argument action can not be null!\n");
  }

  if (undefinedp(action->type)) {
    error("Missing required property type in action\n");
  }

  if (is_dispatching) {
    error("Reducers may not call dispatch!\n");
  }

  State new_state;

  // This is pretty much cloned from the JS version, but it makes no real sense
  // since if dispatch() is called from within a reducer the thrown error in
  // above, in if (is_dispatching), will be caught here and will never bubble
  // up.
  catch {
    is_dispatching = true;
    new_state = reducer(current_state, action);
  };

  is_dispatching = false;

#ifdef REDUX_GREEDY_MUTABLE_CHECK
  // If this flag is set it will be checked that the new state isn't the same
  // as the old state. The downside of this is that you have to make a copy of
  // the state in the reducer even if you don't touch it.

  if (objectp(new_state) || mappingp(new_state) ||
      multisetp(new_state) || arrayp(new_state))
  {
    if (new_state == current_state) {
      error("Objects, mappings, arrays and multisets may not be mutated!\n");
    }
  }
#endif

  current_state = new_state;

  array(Subscriber) listeners = subscribers = next_subscribers;

  foreach (listeners, Subscriber s) {
    s(this, action);
  }

  return action;
}

public this_program clone()
{
  Store s = this_program(reducer, current_state);
  s->dispatch = dispatch;

  foreach (next_subscribers, Subscriber ss) {
    s->subscribe(ss);
  }

  return s;
}

protected void destroy()
{
  // werror("Destroy Store...\n");
  reducer = 0;
  current_state = 0;
  subscribers = 0;
}
