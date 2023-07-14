package main

import "runtime"

//go:noinline
func wrappedPrint(thething int32) {
    println(thething)
}

func printAndYield(n int32) {
    wrappedPrint(n)
    runtime.Gosched()
}

func printOdds() {
    printAndYield(1)
    printAndYield(3)
    printAndYield(5)
    printAndYield(7)
    printAndYield(9)
}

func main() {
    go printOdds()
    runtime.Gosched()
    printAndYield(2)
    printAndYield(4)
    printAndYield(6)
    printAndYield(8)
    printAndYield(10)
}
