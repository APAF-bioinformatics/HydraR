# Restricted State R6 Class

A security wrapper for AgentState that restricts access based on
node_id. Implements "True Privacy" for inter-agent communication.

## Value

A \`RestrictedState\` object.

## Public fields

- `state`:

  AgentState. The underlying global state.

- `node_id`:

  String. The ID of the currently executing node.

- `read_only`:

  Logical. If TRUE, set() and update() are blocked.

- `logger`:

  MessageLog. Audit log for communication.

## Methods

### Public methods

- [`RestrictedState$new()`](#method-RestrictedState-new)

- [`RestrictedState$get()`](#method-RestrictedState-get)

- [`RestrictedState$set()`](#method-RestrictedState-set)

- [`RestrictedState$update()`](#method-RestrictedState-update)

- [`RestrictedState$send_message()`](#method-RestrictedState-send_message)

- [`RestrictedState$receive_messages()`](#method-RestrictedState-receive_messages)

- [`RestrictedState$clear_inbox()`](#method-RestrictedState-clear_inbox)

- [`RestrictedState$get_all()`](#method-RestrictedState-get_all)

- [`RestrictedState$clone()`](#method-RestrictedState-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize RestrictedState

#### Usage

    RestrictedState$new(state, node_id, logger = NULL, read_only = FALSE)

#### Arguments

- `state`:

  AgentState object.

- `node_id`:

  String node ID.

- `logger`:

  Optional MessageLog object.

- `read_only`:

  Logical. If TRUE, blocks all write operations. Restricted Get

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    RestrictedState$get(key, default = NULL)

#### Arguments

- `key`:

  String.

- `default`:

  Default value. Restricted Set

------------------------------------------------------------------------

### Method `set()`

#### Usage

    RestrictedState$set(key, value)

#### Arguments

- `key`:

  String.

- `value`:

  Any. Forward Update

------------------------------------------------------------------------

### Method [`update()`](https://rdrr.io/r/stats/update.html)

#### Usage

    RestrictedState$update(updates)

#### Arguments

- `updates`:

  List. Send Private Message

------------------------------------------------------------------------

### Method `send_message()`

#### Usage

    RestrictedState$send_message(to, content, ...)

#### Arguments

- `to`:

  String. Target node ID.

- `content`:

  Any. Message content.

- `...`:

  Additional metadata. Receive Private Messages

------------------------------------------------------------------------

### Method `receive_messages()`

#### Usage

    RestrictedState$receive_messages()

#### Returns

List of messages for this node. Clear Own Inbox

------------------------------------------------------------------------

### Method `clear_inbox()`

Removes all messages from the node's own inbox. Filtered Get All

#### Usage

    RestrictedState$clear_inbox()

------------------------------------------------------------------------

### Method `get_all()`

#### Usage

    RestrictedState$get_all()

#### Returns

List. All public state variables (no private inboxes).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RestrictedState$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
state <- RestrictedState$new(fields = c("a", "b"))
} # }
```
