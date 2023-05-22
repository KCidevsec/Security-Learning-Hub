#!/bin/bash

label_center()
{
    lenght_of_string=$(($(echo $1 | wc -m) - 1))
    columns=80
    front_spacing=$(($(($columns - $lenght_of_string)) / 2 ))
    back_spacing=$(($front_spacing + $lenght_of_string))
    number_of_front_sympols=5
    number_of_characters_before_back_sympols=76
    for i in $(seq 1 $columns); do echo -n "="; done
    echo ""
    for i in $(seq 1 $columns); do
    {
        if [[ $i -le $number_of_front_sympols ]]
        then
            echo -n "="
        fi

        if [[ $i -lt $front_spacing ]] && [[ $i -gt $number_of_front_sympols ]] 
        then
            echo -n " "
        fi

        if [[ $i -eq $front_spacing ]]
        then
            echo -n $1
        fi

        if [[ $i -gt $back_spacing ]]
        then
        {
            if [[ $i -le $number_of_characters_before_back_sympols ]]
            then
                echo -n " "
            elif [[ $i -gt $number_of_characters_before_back_sympols ]]
            then
                echo -n "="
            fi
        }
        fi
        if [[ $i -eq $columns ]]
        then
            echo -n "="
        fi
    }
    done
    echo ""
    for i in $(seq 1 $columns); do echo -n "="; done
    echo ""
}