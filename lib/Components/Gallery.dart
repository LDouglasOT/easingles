import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Image_gallery extends StatefulWidget {
 
  final List<dynamic> listImages;
  Image_gallery({Key? key, required this.listImages}) : super(key: key);

  @override
  State<Image_gallery> createState() => _Image_galleryState(listImages: listImages);
}

class _Image_galleryState extends State<Image_gallery> {
  final PageController _controller = PageController();

  final List<dynamic> listImages;

  _Image_galleryState({required this.listImages});

  List<Widget> mockImage() {
    List<Widget> images = [];
    for (var i = 0; i < listImages.length; i++) {
      
      images.add(SizedBox(
        child:Image.network(listImages[i].toString())
      ));
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              children: mockImage(),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SmoothPageIndicator(
            controller: _controller,
            count: listImages.length,
            effect: ScrollingDotsEffect(
              activeDotColor: Color.fromARGB(255, 255, 9, 128),
            ),
            
          ),
        ],
      ),
    );
  }
}
