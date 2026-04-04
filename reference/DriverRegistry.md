# Driver Registry R6 Class

A singleton-like registry for managing AgentDriver instances. Enables
runtime recovery and hot-swapping of drivers across nodes.

## Value

A \`DriverRegistry\` R6 object.

## Public fields

- `drivers`:

  List. Storage for registered drivers.

## Methods

### Public methods

- [`DriverRegistry$new()`](#method-DriverRegistry-new)

- [`DriverRegistry$register()`](#method-DriverRegistry-register)

- [`DriverRegistry$get()`](#method-DriverRegistry-get)

- [`DriverRegistry$list_drivers()`](#method-DriverRegistry-list_drivers)

- [`DriverRegistry$remove()`](#method-DriverRegistry-remove)

- [`DriverRegistry$clear()`](#method-DriverRegistry-clear)

- [`DriverRegistry$clone()`](#method-DriverRegistry-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize DriverRegistry

#### Usage

    DriverRegistry$new()

#### Returns

A new \`DriverRegistry\` object. Register a Driver

------------------------------------------------------------------------

### Method `register()`

#### Usage

    DriverRegistry$register(driver, overwrite = FALSE)

#### Arguments

- `driver`:

  AgentDriver object.

- `overwrite`:

  Logical. Whether to overwrite existing driver with same ID.

#### Returns

The registry object (invisibly). Get a Driver

------------------------------------------------------------------------

### Method [`get()`](https://rdrr.io/r/base/get.html)

#### Usage

    DriverRegistry$get(id)

#### Arguments

- `id`:

  String. Driver identifier.

#### Returns

AgentDriver object or NULL. List Registered Drivers

------------------------------------------------------------------------

### Method `list_drivers()`

#### Usage

    DriverRegistry$list_drivers()

#### Returns

Data frame of registered drivers and their metadata. Remove a Driver

------------------------------------------------------------------------

### Method [`remove()`](https://rdrr.io/r/base/rm.html)

#### Usage

    DriverRegistry$remove(id)

#### Arguments

- `id`:

  String.

#### Returns

The registry object (invisibly). Clear Registry

------------------------------------------------------------------------

### Method `clear()`

#### Usage

    DriverRegistry$clear()

#### Returns

The registry object (invisibly).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    DriverRegistry$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
