# SORTING GAME

## Motivation

The best way to learn an algorithm is doing it with your hands! This game is designed to work with the multiple-objects detection system described in [this repository](https://github.com/quantranfr/MultiNFC).

The final product will be used in [ExploraScience Quy Nhon](http://explorascience.vn) - a science center in Vietnam.

It's made in [Godot](https://godotengine.org), an open-source game engine.

## Demo

In this game, a player has to follow the instruction on the screen and place the right cards onto the right card readers. Let's see how quick you can finish this game!

Play the video below to grasp what all of this is about.

[![](http://img.youtube.com/vi/1rLfiI8Qr10/0.jpg)](https://youtu.be/1rLfiI8Qr10)

Of course it's not interesting as is. A complet sorting game (featuring bubble sort algorithm for example) with at least some more cards is on the way.

## Simulation without physical objects

To test this game without having to worry about physical objects, we have to do some simulation. Here are the steps to do it:

* Install `python` and the `websockets` module;
* Run the game;
* Run `python -m websockets ws://127.0.0.1:9080` in your terminal;
* At the prompt, simulate action with the `<reader1:card1>;<reader2:card2>;…` syntax. Note that only readers with a card on it need to be mentioned. For example, the following commands will lead to a win (at the time of writing):

```
R1:62 C9 B1 A9
R1:62 C9 B1 A9;R2:37 5F D1 3C
R1:62 C9 B1 A9;R3:C0 D6 16 32;R2:37 5F D1 3C
R3:C0 D6 16 32;R2:62 C9 B1 A9
R1:37 5F D1 3C;R3:C0 D6 16 32;R2:62 C9 B1 A9
```

![](img/gameplay.png)

## How-to

### Update card IDs

By modifying these lines:

```
var cards = { # number written on cards
	"C0 D6 16 32": "7",
	"37 5F D1 3C": "8",
	"62 C9 B1 A9": "9",
}
```

We can add as many card as we want, whether they will be used in the game or not.

### Update reader IDs

```
var readers = { # position of each reader in the row
	"R1": 0,
	"R2": 1,
	"R3": 2,
}
```

You should ONLY include readers that are used in the game.

## Roadmap

* Make config files to store cardIDs and readerIDs
* Internationalization
* Add more card readers (and also change the sreen to paysage mode)
* Change music

> The assets (audio) are borrowed from [Dodge the Creeps!](https://docs.godotengine.org/en/stable/getting_started/step_by_step/your_first_game.html) - an example game in Godot documentation.
