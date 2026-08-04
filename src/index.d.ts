type Cleanup = () => void
type Key = string | number | symbol

export = Vide
export as namespace Vide

declare namespace Vide {
	/** A state container that can be read and updated. Calling the source
	 * with no arguments will return the stored value, whereas calling it with an
	 * argument (including `undefined`) will update the stored value.
	 * @param value The new value to store.
	 * @returns The current value. */
	type Source<T> = (value?: T) => T

	/** A source that you can read from (but not necessarily write to). */
	type RSource<T> = () => T

	/** A value that can be either a source property or a static value. \
	 * Use `read` to read from such values. */
	type Derivable<T> = T | (() => T)

	/** An object containing the custom logic to invoke when an instance is
	 * created. Created using `action()` */
	interface Action<T extends Instance> {
		callback: (instance: T) => void
	}

	/** A value that can be animated by Vide's spring system. */
	type Animatable = number | CFrame | Color3 | UDim | UDim2 | Vector2 | Vector3 | Rect

	/** Any destructible object that can be passed to `cleanup()`. */
	type Disposable =
		| Cleanup
		| Instance
		| RBXScriptConnection
		| thread
		| { Disconnect(): void }
		| { Destroy(): void }
		| { disconnect(): void }
		| { destroy(): void }

	/** A component return value that can optionally provide a delay time in
	 * seconds before being destroyed. */
	type MaybeDelayed<T> = T | LuaTuple<[T, number?]>

	/** `fn as AssumeDelayed<typeof fn>` will cast the function to use the LuaTuple variant of MaybeDelayed. */
	type AssumeDelayed<Fn> = Fn extends (
		...args: infer Args
	) => MaybeDelayed<infer T>
		? (...args: Args) => LuaTuple<[T, number | undefined]>
		: never;

	/** Strict mode is designed to help the development process by adding
	 * safety checks and identifying improper usage.
	 *
	 * As well as additional safety checks, Vide will dedicate extra
	 * resources to recording and better emitting stack traces where
	 * errors occur, particularly when binding properties to sources.
	 *
	 * It is recommended to develop UI with strict mode and to disable it
	 * when pushing to production. In Roblox, production code compiles at
	 * O2 by default, so you don't need to worry about disabling strict
	 * mode unless you have manually enabled it.
	 *
	 * @see https://centau.github.io/vide/api/strict-mode */
	let strict: boolean
	/** If true, in apply calls, nested properties are assigned after non-nested ones. */
	let defer_nested_properties: boolean
	/** Defaults to true. Set to false if you want to be able to destroy a root node multiple times (repeated destruction has no effect but may imply a bug). */
	let warn_on_repeated_root_destroy: boolean

	/** Creates a new scope, where creation of effects can be tracked
	 * and properly disposed of. Returns the result of the given function.
	 *
	 * A function to destroy the root is passed into the callback, which will
	 * run any cleanups and allow derived sources to garbage collect.
	 *
	 * @param fn The function to run in a new scope.
	 * @param args Arguments to pass to `fn`
	 *
	 * @returns The destroy function, followed by the results of the function.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-core#root */
	// Note: having an overload for `fn` to return void and thus root to return just `Cleanup` fail when in a generic function, or when using void (or not void, depending on if you try to put the void definition first or last)
	function root<T extends unknown[], Args extends unknown[]>(fn: (destroy: Cleanup, ...args: Args) => LuaTuple<T>, ...args: Args): LuaTuple<[Cleanup, ...T]>
	function root<T, Args extends unknown[]>(fn: (destroy: Cleanup, ...args: Args) => T, ...args: Args): LuaTuple<[Cleanup, T]>

	/** Runs a function in a new scope, setting the result's `Parent` to `target`.
	 *
	 * @param component The function to run in a new scope.
	 * @param target The target instance to apply the result to.
	 * @param args Arguments to pass to the component constructor
	 *
	 * @returns A function to destroy the scope.
	 *
	 * @see https://centau.github.io/vide/api/creation#mount */
	function mount<T, Args extends unknown[]>(component: T extends void ? never : (...args: Args) => T, target: Instance, ...args: Args): LuaTuple<[Cleanup, T]>

	/** Creates or clones a new instance and applies any given properties & children.
	 *
	 * Be cautious calling this in an effect/derive call, as this will trigger the creation of new instances every time the state changes. Prefer to use `apply` with an object pool or create the instance in a manually controlled scope with `root`/`branch`.
	 *
	 * Note that the instance is destroyed on cleanup.
	 *
	 * @param className The class name of the instance to create, or an instance to clone.
	 * @param props The properties to apply to the new instance. Property values can point to sources.
	 * @param children The list of children and/or sources of properties and/or children (and/or more sources). You could pass this in with `props` instead, but this is here for TS-convenience (so you should use `{}` for props and `[]` for children).
	 *
	 * @see https://centau.github.io/vide/api/creation#create */
	function create<K extends keyof CreatableInstances>(
		className: K,
		props?: InstanceProps<CreatableInstances[K]>,
		children?: Node<CreatableInstances[K]>[],
	): CreatableInstances[K]
	function create<T extends Instance>(
		objToClone: T,
		props?: InstanceProps<T>,
		children?: Node<T>[],
	): T

	/** Creates a state container that can be read and updated (from anywhere - being in a scope is not required).
	 * Calling the source with no arguments will return the stored value, whereas calling
	 * it with an argument (including `undefined`) will update the stored value.
	 *
	 * Accessing the value while in an effect/derive call will track the dependency unless you read the value with `untrack`.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-core#source */
	function source<T>(initialValue: T): Source<T>
	// convenience overload for when the initial value is optional
	function source<T>(): Source<T | undefined>

	/** Runs a side-effect in a new scope when any of its dependencies
	 * change. Any time a source referenced in the callback is updated, the
	 * callback will be rerun. The callback is run once immediately.
	 *
	 * Optionally, the callback can return a value that will be passed during
	 * the next rerun. This can be useful for comparing values between runs.
	 *
	 * Must be called in a scope.
	 *
	 * (`effect` is similar to calling `derive` with a void function.)
	 *
	 * @param callback The side-effect to run when dependencies change.
	 * @param initialValue Optional initial argument to pass to the callback.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-core#effect */
	function effect(callback: () => void): void
	// overload where callback stores a value between runs
	function effect<T>(callback: (value: T) => T, initialValue: T): void

	/** Derives a new source in a new scope from existing sources. The
	 * derived source will have its value recalculated and cached when any source
	 * it derives from is updated.
	 *
	 * Must be called in a scope.
	 *
	 * Tip: when using `create`/`apply`, passing in a function with `derive` is redundant. In general it's beneficial to use derive in any of these cases:
	 *
	 * - You are creating a source that updates less frequently than its input sources
	 * - You are using the resulting value in multiple places (so caching the result is valuable)
	 *
	 * @see https://centau.github.io/vide/api/reactivity-core#derive */
	function derive<T>(source: () => T): RSource<T>

	/** Shows one of a set of components depending on an input source and a
	 * mapping table. Returns a source holding an instance of the currently
	 * rendered component.
	 *
	 * When the input source changes, the new value will be used to lookup a
	 * given mapping table to get a component. During the next change, the
	 * scope the component was created in will be destroyed, and a new
	 * component created under a new scope.
	 *
	 * @param source The source to match against.
	 * @param map The mapping table of components.
	 *
	 * @returns A source holding the currently rendered component.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-flow#switch */
	// switch is a reserved keyword
	function match<Match extends Key, Result>(
		source: () => Match,
	): (map: { [P in Match]?: (show: () => boolean) => MaybeDelayed<Result> }) => () => Result | undefined

	/** Shows one of two components depending on an input source. Returns a source
	 * holding an instance of the currently rendered component.
	 *
	 * When the input source changes from a falsey to a truthy value, the
	 * component will be reran under a new scope. If it changes from
	 * a truthy to falsey value, the scope the component was created
	 * in will be destroyed, and the returned source will output `nil`, or
	 * a fallback component if given.
	 *
	 * @param source The source to match against.
	 * @param component The component to render when the source is truthy.
	 * @param fallback The component to render when the source is falsey.
	 *
	 * @returns A source holding the currently rendered component.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-flow#show */
	function show<Condition, Result, Fallback = undefined>(
		source: () => Condition,
		component: (value: () => NonNullable<Condition>, show: () => boolean) => MaybeDelayed<Result>,
		fallback?: (show: () => boolean) => MaybeDelayed<Fallback>,
	): () => Result | Fallback

	/** Maps each _key_ in a table source to a component. Returns a source holding
	 * an array of the rendered components.
	 *
	 * When the input source changes, each key in the new table is compared with
	 * the last input table.
	 * - For any new key, the transform function is ran under a new scope
	 *   to produce a new instance.
	 * - For any removed key, the scope for that key is destroyed.
	 * - Keys whose values have changed will be untouched.
	 *
	 * @param input The table source to map over.
	 * @param component The function to transform each value in the table.
	 *
	 * @returns A source holding an array of the rendered components.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-flow#indexes */
	// overload for an array input
	function indexes<VI, VO>(
		input: () => readonly VI[],
		component: (value: () => VI, index: number, show: () => boolean) => MaybeDelayed<VO>,
	): () => VO[]
	// overload for a map input
	function indexes<K, VI, VO>(
		input: () => Map<K, VI> | ReadonlyMap<K, VI>,
		component: (value: () => VI, key: K, show: () => boolean) => MaybeDelayed<VO>,
	): () => VO[]
	// overload for an object input
	function indexes<K extends Key, VI, VO>(
		input: () => { readonly [P in K]: VI },
		component: (value: () => VI, key: K, show: () => boolean) => MaybeDelayed<VO>,
	): () => VO[]

	/** Maps each _value_ in a table source to a component. Returns a source
	 * holding an array of the rendered components.
	 *
	 * When the input source changes, each value in the new table is compared
	 * with the last input table.
	 * - For any new value, the transform function is run under a new
	 *   scope to produce a new instance.
	 * - For any removed value, the scope for that value is destroyed.
	 * - Values whose keys have changed will be untouched.
	 *
	 * **CAUTION:** Having primitive values in the input source table can cause
	 * unexpected behavior, as duplicate values can result in multiple tranforms
	 * being ran for a single value. It is recommended to use a table with unique
	 * values to avoid this issue.
	 *
	 * @param input The table source to map over.
	 * @param component The function to transform each value in the table.
	 *
	 * @returns A source holding an array of the rendered components.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-flow#values */
	// overload for an array input
	function values<VI, VO>(
		input: () => readonly VI[],
		component: (value: VI, index: () => number, show: () => boolean) => MaybeDelayed<VO>,
	): () => VO[]
	// overload for a map input
	function values<K, VI, VO>(
		input: () => Map<K, VI> | ReadonlyMap<K, VI>,
		component: (value: VI, key: () => K, show: () => boolean) => MaybeDelayed<VO>,
	): () => VO[]
	// overload for an object input
	function values<K extends Key, VI, VO>(
		input: () => { readonly [P in K]: VI },
		component: (value: VI, key: () => K, show: () => boolean) => MaybeDelayed<VO>,
	): () => VO[]

	/** Runs the callback function when the current scope reruns or is destroyed.
	 * Should be used to clean up instances and connections created in the scope.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-utility#cleanup */
	function cleanup(value: Disposable): void

	/** Reads from `source` without tracking it.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-utility#untrack */
	function untrack<T>(source: () => T): T

	/** Reads the source and returns its value, returning non-source values as-is.
	 *
	 * Useful for component props that can be either static or dynamic.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-utility#read */
	function read<T>(source: Derivable<T>): T

	/** Runs `setter`, delaying processing the effects of any source updates until `setter` is done.
	 *
	 * Note: at this time, if you change a source and then revert the change within the batch call, triggered effects will still reprocess once (instead of cancelling).
	 *
	 * @param setter The function to run.
	 *
	 * @see https://centau.github.io/vide/api/reactivity-utility#batch */
	function batch(setter: () => void): void

	/** Returns a new source with a value always moving towards the `goal`. The spring will oscillate around the input value until it reaches equilibrium.
	 *
	 * @param period The time in seconds it takes for the spring to complete one
	 * full cycle if undamped. For a dampingRatio of 1.0, you can expect the spring to get 98% of the way there within `period` and to settle within `2 * period`.
	 * @param dampingRatio The amount of resistance applied to the spring.
	 *
	 * @returns A tuple containing the spring value source (which you can modify to set the position) and a configuration function to set the spring's position, velocity, and/or to apply impulses.
	 *
	 * @see https://centau.github.io/vide/api/animation#spring */
	function spring<T extends Animatable>(
		goal: Derivable<T>,
		period?: number,
		dampingRatio?: number,
	): LuaTuple<[value: Source<T>, config: (config: SpringConfig<T>) => void]>

	type SpringConfig<T extends Animatable> = { position?: T; velocity?: T; impulse?: T }

	/** Creates an Action that can be passed to `create`/`apply` to invoke custom
	 * actions on instances. The callback will be invoked when the instance is
	 * created, after properties and children are applied.
	 *
	 * @param callback The function to run when the instance is created. If you need to react to state changes, use `effect` inside the callback.
	 *
	 * @see https://centau.github.io/vide/api/creation#action */
	function action<T extends Instance>(callback: (instance: T) => void): Action<T>

	/** Creates an Action that runs the callback when a property changes on an
	 * instance. The callback will be invoked once initially and every time the
	 * property changes.
	 *
	 * To be used in the properties list for create/apply calls.
	 *
	 * @param key The property to watch for changes.
	 * @param callback The function to run when the property changes.
	 *
	 * @see https://centau.github.io/vide/api/creation#changed */
	function changed<T extends Instance, K extends keyof WritableInstanceProperties<T>>(
		key: K,
		callback: (value: WritableInstanceProperties<T>[K]) => void,
	): Action<T>

	/** Applies properties and children to an existing instance.
	 *
	 * @param instance The instance to apply properties to.
	 * @param props The properties to apply to the new instance. Property values can point to sources.
	 * @param children The list of children and/or sources of properties and/or children (and/or more sources). You could pass this in with `props` instead, but this is here for TS-convenience (so you can use `[]`).
	 * @param destroy If true, on cleanup will destroy `instance` instead of deparenting it
	 *
	 * @returns The instance with the properties applied. */
	function apply<T extends Instance>(instance: T, props?: InstanceProps<T>, children?: Node<T>[], destroy?: boolean): T

	/** By default, springs run at 120 Hz in the `Heartbeat` event. Calling this
	 * function can change when the solver runs, which will advance the simulation
	 * time by `deltaTime` seconds.
	 *
	 * Once called, the internal solver will disconnect to allow the user to
	 * advance the simulation time manually.
	 *
	 * @param deltaTime The time in seconds to advance the simulation.
	 *
	 * @see https://centau.github.io/vide/api/animation#spring */
	function step(deltaTime: number): void

	/** Create a stable sibling "branch scope" to the current scope.
	 *
	 * Must be called inside a scope where the parent is a scope. For example, you can call this while in an `effect` call.
	 *
	 * Very similar to root, except that the branch is automatically cleaned up with the parent scope, so you don't need to say `cleanup(destroyBranch)`.
	 * @param args The arguments to send to `fn` */
	function branch<T extends any[], Args extends any[]>(
		fn: (...args: Args) => LuaTuple<T>,
		...args: Args
	): LuaTuple<[Cleanup, ...T]>
	function branch<T, Args extends any[]>(fn: (...args: Args) => T, ...args: Args): LuaTuple<[Cleanup, T]>

	// Context

	interface Context<T> {
		/** Get the context's value.
		 *
		 * (Note that this operation is not O(1), so don't read from it repeatedly.) */
		(): T
		/** Set the context's value for the duration of `component`. Only valid while inside a scope. */
		<U>(value: T, component: () => U): U extends LuaTuple<any> ? never : U
	}

	/** Creates a new context that can be used to customize components. Useful to avoid passing configuration parameters through many intermediate/nested components.
	 *
	 * @example
	 * ```tsx
	 * const theme = context("light")
	 *
	 * <frame>
	 *   {theme("dark", () => {
	 *     return <textlabel Text={theme()} />
	 *   })}
	 * </frame>
	 * ```
	 * @template T The type of value to store in the context.
	 * @param defaultValue The default value to store in the context. */
	function context<T>(defaultValue?: T): Context<T>

	// Elements

	/** A value that can be passed to the `create()` function.
	 * @template T The type of instance to create. */
	export type Node<T extends Instance = Instance> =
		| InstanceProps<T>
		| Action<T>
		| (() => Node<T> | undefined)
		| Instance
		| Nodes<T>

	/** A collection of nodes. Vide unwraps these values when rendering, allowing for nested arrays and properties to be passed as children. */
	type Nodes<T extends Instance = Instance> =
		| Map<number, Node<T>>
		| ReadonlyMap<number, Node<T>>
		| readonly Node<T>[]
		| { readonly [key: number]: Node<T> }

	/** Infers the names of the enum values from an enum item. Resolves to a union
	 * of the enum items and their respective names. */
	type InferEnumNames<T> = T extends EnumItem ? T | T["Name"] : T

	/** Instance properties that can be written to or assigned Vide sources. */
	type InstancePropertySources<T extends Instance> = {
		[K in keyof WritableInstanceProperties<T>]?: Derivable<InferEnumNames<WritableInstanceProperties<T>[K]>>
	}

	/** Instance event properties that can be passed a callback function. */
	type InstanceEventCallbacks<T extends Instance> = {
		[K in InstanceEventNames<T>]?: T[K] extends RBXScriptSignal<(...args: infer A) => void>
			? (...args: A) => void
			: never
	}

	/** Instance properties and events that can be used with the `create`/`apply` functions. */
	type InstanceProps<T extends Instance> = InstancePropertySources<T> & InstanceEventCallbacks<T>
}
