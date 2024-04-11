package main

import (
	"encoding/json"
	"fmt"
	"reflect"
)

type ExampleStruct struct {
	Name        string `flag:"true"`
	Age         int
	Description string
	Sub         struct {
		SubName    string `flag:"true"`
		SubAge     int
		SubAddress string
	}
}

func CreateMapFromStruct(input interface{}) (map[string]interface{}, error) {
	v := reflect.ValueOf(input)
	if v.Kind() == reflect.Ptr {
		v = v.Elem()
	}
	t := v.Type()

	result := make(map[string]interface{})

	for i := 0; i < v.NumField(); i++ {
		field := v.Field(i)
		fieldType := t.Field(i)

		// Add the field to the result map
		if tag := fieldType.Tag.Get("flag"); tag == "true" {
			result[fieldType.Name+"_flag"] = true
		}

		// Recursively process nested struct fields
		if field.Kind() == reflect.Struct {
			subMap, err := CreateMapFromStruct(field.Interface())
			if err != nil {
				return nil, err
			}
			result[fieldType.Name] = subMap
		} else {
			// Add non-struct fields to the result map
			result[fieldType.Name] = field.Interface()
		}
	}

	return result, nil
}
// main, expected ouput:
// {
// 	"Age": 30,
// 	"Description": "A sample struct",
// 	"Name": "John",
// 	"Name_flag": true,
// 	"Sub": {
// 	  "SubAddress": "123 Main St",
// 	  "SubAge": 20,
// 	  "SubName": "SubJohn",
// 	  "SubName_flag": true
// 	}
//   }
func main() {
	example := ExampleStruct{
		Name:        "John",
		Age:         30,
		Description: "A sample struct",
		Sub: struct {
			SubName    string `flag:"true"`
			SubAge     int
			SubAddress string
		}{
			SubName:    "SubJohn",
			SubAge:     20,
			SubAddress: "123 Main St",
		},
	}

	result, err := CreateMapFromStruct(&example)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	jsonResult, _ := json.MarshalIndent(result, "", "  ")
	fmt.Println(string(jsonResult))
}
