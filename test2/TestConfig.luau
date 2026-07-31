local vide = game.ReplicatedStorage.vide
return {
	inherits = false,
	requireTimeout = 0.1,
	initTimeout = 0.1,
	timeout = 2,
	alwaysRefresh = {vide.graph, vide.spring},
}