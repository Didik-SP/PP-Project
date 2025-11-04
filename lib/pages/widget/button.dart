import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

// Widget untuk custom text field yang digunakan di signin dan signup
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final double marginBottom;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.marginBottom = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              prefixIcon,
              color: Color(0xFF8B4513),
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF8B4513),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

// Widget untuk tombol gradient yang digunakan di signin dan signup
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color>? gradientColors;
  final double? width;
  final double height;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.gradientColors,
    this.width,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors ?? [Color(0xFF8B4513), Colors.deepOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B4513).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Widget untuk profile image yang digunakan di signin dan signup
class ProfileImage extends StatelessWidget {
  final double radius;
  final String imagePath;
  final bool hasCircleAvatar; // untuk signin yang menggunakan CircleAvatar
  final bool hasBoxShadow;

  const ProfileImage({
    Key? key,
    this.radius = 60,
    this.imagePath = 'assets/images/profile.png',
    this.hasCircleAvatar = false,
    this.hasBoxShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hasCircleAvatar) {
      // Style untuk signin
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: hasBoxShadow
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: radius - 3,
            backgroundImage: AssetImage(imagePath),
          ),
        ),
      );
    } else {
      // Style untuk signup
      return Container(
        height: radius * 2,
        width: radius * 2,
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: hasBoxShadow
              ? [
                  BoxShadow(
                    color: Color(0xFF8B4513).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
}

// Widget untuk link text yang digunakan di signin dan signup
class LinkText extends StatelessWidget {
  final String normalText;
  final String linkText;
  final VoidCallback onTap;
  final TextAlign textAlign;

  const LinkText({
    Key? key,
    required this.normalText,
    required this.linkText,
    required this.onTap,
    this.textAlign = TextAlign.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        children: [
          TextSpan(
            text: normalText,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}

// Widget untuk password visibility toggle
class PasswordVisibilityIcon extends StatelessWidget {
  final bool obscureText;
  final VoidCallback onPressed;

  const PasswordVisibilityIcon({
    Key? key,
    required this.obscureText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey[600],
        size: 20,
      ),
      onPressed: onPressed,
    );
  }
}

// Widget untuk custom app bar dengan back button (untuk signup)
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                  size: 18,
                ),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              ),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Widget untuk social media button (untuk signin)
class SocialMediaButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const SocialMediaButton({
    Key? key,
    required this.imagePath,
    required this.onPressed,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B4513).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 28,
            height: 28,
          ),
        ),
      ),
    );
  }
}
