import 'package:flutter/material.dart';

class MyCard extends StatelessWidget {

  final double balance;
  final int card_number;
  final int year;
  final int month;
  final color;
  
  const MyCard({
  // super.key
  required this.month,
  required this.balance,
  required this.card_number,
  required this.year,
  required this.color
  });

  @override
  Widget build(BuildContext context) {
    return 
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16)
              ),
              padding:const EdgeInsets.symmetric(horizontal: 25),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height:13),
                  Text('Balance',style:TextStyle(
                    color: Colors.white,
                    fontSize:20
                  )),
                  Text('\$ '+balance.toString(),style:TextStyle(
                    color: Colors.white,
                    fontSize:32
                  )),
                  SizedBox(height:20),
                  Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text('****'+card_number.toString(),style:TextStyle(
                    color: Colors.white,
                    fontSize:20
                  )),
                    Text(month.toString()+'/'+year.toString(),style:TextStyle(
                    color: Colors.white,
                    fontSize:20
                  ))
                  ],),
                  SizedBox(height:16),
                ],
              ),
            ),
          );
  }
}