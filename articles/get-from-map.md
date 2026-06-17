---
title: "Goでネストしたマップから値を取り出す再帰関数"
emoji: "🗺️"
type: "tech"
topics: ["go", "json", "map", "recursion"]
published: true
---

Recently, I received a response from an API that contained a JSON with a complex, large, and nested structure. I needed to access a specific value inside that structure, but the path to that value could vary.

The idea was to create a recursive function that takes a list with the path to the desired value and the data structure (a nested map) and returns the corresponding value, if found.

There are probably smarter ways to do this, but this recursive approach worked well for my case.

```go
package main

import (
	"fmt"
)

func GetFromMap(parts []string, current any) (any, bool) {
	fmt.Printf("parts: %v, current: %v\n", parts, current)

	if len(parts) == 0 {
		return current, true
	}

	m, ok := current.(map[string]any)
	if !ok { // not a map, cannot descend
		return nil, false
	}

	key := parts[0]
	next, exists := m[key]
	if !exists {
		return nil, false
	}

	return GetFromMap(parts[1:], next)
}

func MustGetFromMap(path []string, data any) any {
	val, ok := GetFromMap(path, data)
	if !ok {
		panic(fmt.Sprintf("path %v not found in map", path))
	}
	return val
}
```

And here is an example of how you can test this function:

```go
package main

import "testing"

func TestGetFromMap(t *testing.T) {
	data := map[string]any{
		"not_a_map": "just a string",
		"a": map[string]any{
			"b": map[string]any{
				"c": 42,
			},
			"d": "hello",
		},
		"x": 3.14,
	}

	tests := []struct {
		path          []string
		expectedVal   any
		expectedFound bool
	}{
		{
			path:          []string{"a", "b", "c"},
			expectedVal:   42,
			expectedFound: true,
		},
		{
			path:          []string{"a", "d"},
			expectedVal:   "hello",
			expectedFound: true,
		},
		{
			path:          []string{"x"},
			expectedVal:   3.14,
			expectedFound: true,
		},
		{
			path:          []string{"a", "not_found"},
			expectedVal:   nil,
			expectedFound: false,
		},
	}

	for _, tt := range tests {
		val, found := GetFromMap(tt.path, data)
		if found != tt.expectedFound {
			t.Errorf("GetFromMap(%v) found = %v; want %v", tt.path, found, tt.expectedFound)
		}
		if val != tt.expectedVal {
			t.Errorf("GetFromMap(%v) = %v; want %v", tt.path, val, tt.expectedVal)
		}
	}
}
```

And please, when you design an API, remember the fellow programmer who will consume it. Simple, flat structures that don't change shape often are better. In fact, simple is always better.
