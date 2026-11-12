import 'package:apni_factory/provider/sign_up_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/screens/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SignUpProvider>(context, listen: false);
    provider.mobileNumberController.addListener(() {
      provider.onMobileChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<SignUpProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Official Logo and Brand Tagline
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppAssetImage.logo,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      "Wholesale Trade Registration",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Registration Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Create Account",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Join India's B2B marketplace",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Text(
                                "FREE SIGNUP",
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Full Name / Business Name
                        _buildFieldLabel("Full Name / Business Name"),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: provider.nameController,
                          hint: "e.g. Ramesh Hardware & Paint Store",
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),

                        // Email Field with Inline Verification
                        _buildFieldLabel("Email Address"),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: provider.emailController,
                                hint: "business@email.com",
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !provider.isEmailOtpvVerified,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (provider.loadingGetEmailOtp)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
                                ),
                              )
                            else if (provider.isEmailOtpvVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Verified",
                                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: () {
                                  final email = provider.emailController.text.trim();
                                  if (email.isNotEmpty) {
                                    provider.getEmailOtp(height, context: context, email: email);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    "Verify",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Email OTP Input Row (if received)
                        if (provider.isEmailOtpReceived && !provider.isEmailOtpvVerified) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: provider.emailOtpController,
                                    hint: "Enter Email OTP",
                                    icon: Icons.pin_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                provider.loadingVerifyEmailOtp
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                                      )
                                    : InkWell(
                                        onTap: () {
                                          provider.verifyEmailOtp(
                                            height,
                                            context: context,
                                            email: provider.emailController.text.trim(),
                                            otp: provider.emailOtpController.text.trim(),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEA580C),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "Submit OTP",
                                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Mobile Number Field with Inline Verification
                        _buildFieldLabel("10-Digit Mobile Number"),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: provider.mobileNumberController,
                                hint: "9876543210",
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                enabled: !provider.isMobileOtpVerified,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (provider.loadingGetMobileOtp)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
                                ),
                              )
                            else if (provider.isMobileOtpVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Verified",
                                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                              )
                            else if (provider.mobileNumberController.text.length == 10)
                              InkWell(
                                onTap: () {
                                  provider.getMobileOtp(
                                    height,
                                    context: context,
                                    mobile: provider.mobileNumberController.text.trim(),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    "Verify",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Mobile OTP Input Row (if received)
                        if (provider.isMobileOtpReceived && !provider.isMobileOtpVerified) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "WhatsApp OTP sent to +91 ${provider.mobileNumberController.text.trim()}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9A3412),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => provider.getMobileOtp(
                                        height,
                                        context: context,
                                        mobile: provider.mobileNumberController.text.trim(),
                                      ),
                                      child: Text(
                                        "Resend",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFEA580C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: provider.mobileOtpController,
                                    hint: "Enter Mobile OTP",
                                    icon: Icons.pin_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                provider.loadingVerifyMobileOtp
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEA580C)),
                                      )
                                    : InkWell(
                                        onTap: () {
                                          provider.verifyMobileOtp(
                                            height,
                                            context: context,
                                            mobile: provider.mobileNumberController.text.trim(),
                                            otp: provider.mobileOtpController.text.trim(),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEA580C),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "Submit OTP",
                                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Password Field
                        _buildFieldLabel("Create Password"),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: provider.passwordController,
                          hint: "At least 6 characters",
                          icon: Icons.lock_outline_rounded,
                          obscureText: provider.isPasswordVisible,
                          suffixIcon: InkWell(
                            onTap: () => provider.passwordVisibility(),
                            child: Icon(
                              provider.isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password Field
                        _buildFieldLabel("Confirm Password"),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: provider.confirmPasswordController,
                          hint: "Re-enter password",
                          icon: Icons.lock_outline_rounded,
                          obscureText: provider.isConfirmPasswordVisible,
                          suffixIcon: InkWell(
                            onTap: () => provider.confirmPasswordVisibility(),
                            child: Icon(
                              provider.isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms Note
                        Text(
                          "By creating an account, you agree to Apni Factory's B2B Terms of Trade & Privacy Policy.",
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Sign Up Button
                        InkWell(
                          onTap: provider.loadingSignUp
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  provider.signUp(
                                    height,
                                    context: context,
                                    name: provider.nameController.text.trim(),
                                    email: provider.emailController.text.trim(),
                                    mobileNumber: provider.mobileNumberController.text.trim(),
                                    password: provider.passwordController.text.trim(),
                                    confirmPassword: provider.confirmPasswordController.text.trim(),
                                    regby: "app",
                                  );
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48).withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: provider.loadingSignUp
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Create Wholesale Account",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already Have Account Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            "Sign In",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF334155),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          counterText: "",
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 19),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
