import 'package:flutter/material.dart';

class pdf_view extends StatelessWidget {
  const pdf_view({super.key});

  @override
  Widget build(BuildContext context) {


    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          child: Icon(Icons.arrow_back_ios),
          onTap: (){
            Navigator.pop(context);
          },
        ),
        actions: [
          GestureDetector(
            child: Icon(Icons.sim_card_download_outlined),
            onTap: (){
              print('downloading........');
            },
          ),
          SizedBox(width: width*0.05,),
        ],
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [new BoxShadow(
                color: Colors.red,
                blurRadius: 3.0,
              ),],
            ),

          ),
        ),
      ),
    );
  }
}
