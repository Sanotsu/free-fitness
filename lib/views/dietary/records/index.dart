import 'package:flutter/material.dart';

import 'foods/food_list.dart';

class DietaryRecords extends StatefulWidget {
  const DietaryRecords({super.key});

  @override
  State<DietaryRecords> createState() => _DietaryRecordsState();
}

class _DietaryRecordsState extends State<DietaryRecords> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DietaryRecords'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoodList()),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: 4,
        itemBuilder: (BuildContext context, int index) {
          return _buildCard();
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }

  _buildCard() {
    return const Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.album),
              title: Text('Breakfast'),
              subtitle: Text('eat a good breakfast.'),
            ),
            Divider(),
            ExpansionTile(
              title: Text('2项'),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.album),
                  title: Text('food1 名称'),
                  subtitle: Text('food 1 重量.'),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Text'),
                        Icon(Icons.star),
                      ],
                    ),
                  ),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.album),
                  title: Text('food2'),
                  subtitle: Text('food 2 description.'),
                  trailing: Icon(Icons.arrow_forward),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Text'),
                      Icon(Icons.star),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
