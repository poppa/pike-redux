//! Redux is a predictable state container originally written in JavaScript
//! and for Javascript apps. This is a Pike implementation of that state
//! container. For more info on the original implementation see
//! @url{https://github.com/reactjs/redux@}.
//!
//! Shortly Redux is a state container that never mutates. Every time the state
//! is changed a new version of the state is created.

//! The type signature of what @[create_store] returns.
typedef mapping(string:function) Store;

//! The type signature of a reducer function.
//! A reducer function gets a @[State] object as first argument and an
//! @[Action] as its second and always returns a @[State] object.
typedef function(.State, Action : .State) Reducer;


//! Thunk middleware. Use as argument to @[apply_middleware()].
function thunk = .Middleware.create_thunk();


//! Default action types.
class ActionType {
  //! Action type sent to all reducers upon store creation, or if a reducer
  //! is swapped in an existing store.
  constant INIT = "@@redux/INIT";
}

//! Default action. This only contain an action type and no payload. All
//! actions must implement this interface, that is all actions must at least
//! have a @[type] member.
class Action(string type) {
  //! @ignore
  string _sprintf(int t) {
    return sprintf("%O(type=%O)", object_program(this), type);
  }
  //! @endignore
}


//! Creates a new Redux store.
//!
//! @param reducer
//! @param preloaded_state
//!  Optional initial state. If not given the reducer/reducers must return
//!  an intial state if the state given as argument to it/them in undefined.
//! @param enchancer
//!  A function that takes @[create_store] as argument and returns a new
//!  @[create_store] function. A function like this is most likely created as
//!  a middleware function via @[apply_middleware()].
//!
//! @returns
//!  @mapping
//!   @member function(Action:Action) "dispatch"
//!    The @tt{dispatch@} function takes an @[Action] as argument and will call
//!    all @[reducer]s with the current @[State] as first argument and the
//!    @tt{action@} as second. It will return the same action it got.
//!
//!   @member function(function(Action:void):function(void:void)) "subscribe"
//!    Registers listener which will be called every time the state is updated.
//!    It will return a function which can be used to unsubscribe the
//!    subscriber function.
//!
//!   @member function(void:.State) "get_state"
//!    Returns the current @[.State] object.
//!
//!   @member function(Reducer:void) "replace_reducer"
//!    Replaces the current reducer function with a new one.
//!  @endmapping
Store create_store(Reducer reducer, void|.State preloaded_state,
                   void|function enhancer)
{
  if (!zero_type(enhancer)) {
    return enhancer(this_function)(reducer, preloaded_state);
  }

  function current_reducer = reducer;
  .State current_state = preloaded_state;
  array current_listeners = ({});
  array next_listeners = current_listeners;
  bool is_dispatching = false;


  void ensure_can_mutate_listeners() {
    if (next_listeners == current_listeners) {
      next_listeners = current_listeners + ({});
    }
  };


  .State get_state() {
    return current_state;
  };


  function subscribe(function listener) {
    bool is_subscribed = true;

    ensure_can_mutate_listeners();
    next_listeners += ({ listener });

    return lambda () {
      if (!is_subscribed) {
        return;
      }

      is_subscribed = false;

      ensure_can_mutate_listeners();
      next_listeners -= ({ listener });
    };
  };


  Action dispatch(Action|mapping action) {
    if (mappingp(action)) {
      if (!has_index(action, "type")) {
        error("Missing index \"type\" in action!\n");
      }
    }

    if (is_dispatching) {
      error("Reducers may not dispatch actions\n");
    }

    is_dispatching = true;
    current_state  = current_reducer(current_state, action);
    is_dispatching = false;

    array listeners = current_listeners = next_listeners;

    foreach (listeners, function listener) {
      listener(action);
    }

    return action;
  };


  void replace_reducer(Reducer reducer) {
    current_reducer = reducer;
    dispatch(Action(ActionType.INIT));
  };

  dispatch(Action(ActionType.INIT));

  return set_weak_flag(([
    "dispatch": dispatch,
    "subscribe": subscribe,
    "get_state": get_state,
    "replace_reducer": replace_reducer
  ]), Pike.WEAK_VALUES);
}

//! Bind an action creator.
//!
//! @example
//! @code
//! Redux.Store store = Redux.create_store(...);
//! function inc = Redux.bind_action_creator(lambda(int val) {
//!   return ([ "type": "inc", val ]);
//! }, store->dispatch);
//!
//! // Dispatch an action of type "inc" with value 4
//! inc(4);
//!
//! // Dispatch an action of type "inc" with value 21
//! inc(21);
//! @endcode
//!
//! @seealso
//!  @[bind_action_creators()]
//!
//! @param action_creator
//!  A function creating an @[Action]
//! @param dispatch
//!  The dispacher function returned from @[create_store()]
function bind_action_creator(function action_creator, function dispatch)
{
  return lambda (mixed ... args) {
    dispatch(action_creator(@args));
  };
}

//! Bind multiple action creators to a single instance.
//!
//! @example
//! @code
//! class my_action_creator {
//!   Redux.Action inc(int payload) {
//!     return ([ "type" : "inc" : payload ]);
//!   }
//!
//!   Redux.Action dec(int payload) {
//!     return ([ "type" : "dec" : payload ]);
//!   }
//! }
//!
//! Redux.Store store = Redux.create_store(...);
//! mapping(string:function) action;
//! action = Redux.bind_action_creators(my_action_creator, store->dispatch);
//!
//! action->inc(4);
//! action->dec(2);
//! @endcode
//!
//! @seealso
//!  @[bind_action_creator()]
//!
//! @param action_creator
//!  This can be a mapping, program or an object where the properties that are
//!  functions will become an action creator function, and will be a member
//!  with the same name in the returned mapping.
//!
//! @param dispatch
//!  The dispacher function returned from @[create_store()]
//!
//! @returns
//!  A mapping where each member will be a function of the same name as the
//!  corresponding property in the argument @[action_creator]
mapping(string:function)
bind_action_creators(mapping|program|object action_creator,
                     function dispatch)
{
  array(mixed) keys = indices(action_creator);
  mapping(string:function) bound_creators = ([]);

  object creator_instance;

  if (programp(action_creator)) {
    creator_instance = action_creator();
  }
  else {
    creator_instance = action_creator;
  }

  foreach (indices(creator_instance), string name) {
    if (functionp(creator_instance[name])) {
      bound_creators[name] =
        bind_action_creator(creator_instance[name], dispatch);
    }
  }

  return bound_creators;
}


//! Combine multiple reducers to a single reducer. Each sub reducer will be
//! called only with the part of the state it's setup to receive.
//!
//! @param reducers
//!  The members in the mapping should correspond to the key in the state they
//!  should receiver. See @[create_store()] for a description of a reducer
//!  function.
Reducer combine_reducers(mapping(string:function) reducers)
{
  mapping(string:function) final_reducers = reducers + ([]);
  mapping init_state_map = mkmapping(indices(reducers),
                                     allocate(sizeof(reducers), UNDEFINED));

  return lambda (.State state, Action action) {
    bool has_changed = false;

    if (!state) {
      state = .State(([]));
    }

    .State next_state = .State(init_state_map + ([]));

    foreach (final_reducers; string key; Reducer reducer) {
      .State prev_state_for_key = state && state[key];
      .State next_state_for_key = reducer(prev_state_for_key, action);

      if (zero_type(next_state_for_key)) {
        error("Undefined state returned from reducer!\n");
      }

      next_state[key] = next_state_for_key;
      has_changed = has_changed ||
                    (objectp(next_state_for_key) &&
                     !objectp(prev_state_for_key)) ||
                    prev_state_for_key != next_state_for_key;
    }

    return has_changed ? next_state : state;
  };
}


//! Apply middlewares.
//!
//! @fixme
//!  Document this...
function apply_middleware(function ... middlewares)
{
  return lambda (typeof(create_store) create_store) {
    return lambda (Reducer reducer, void|.State preloaded_state,
                   void|function enhancer)
    {
      Store store;
      store = create_store(reducer, preloaded_state, enhancer);
      function dispatch = store->dispatch;
      mapping(string:function) middlewar_api = ([
        "get_state": store->get_state,
        "dispatch": lambda (Action action) {
          return dispatch(action);
        }
      ]);

      array chain = map(middlewares, lambda (function middleware) {
        return middleware(middlewar_api);
      });

      dispatch = Function.composite(@chain)(store->dispatch);
      return store + ([ "dispatch" : dispatch ]);
    };
  };
}

/*
  Author: Pontus Östlund <https://github.com/poppa>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/
