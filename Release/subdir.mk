################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
XC_SRCS += \
../main.xc 

XN_SRCS += \
../XDK.xn 

OBJS += \
./main.o 

XC_DEPS += \
./main.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.xc
	@echo 'Building file: $<'
	@echo 'Invoking: XC Compiler'
	xcc -O2 -g -Wall -c -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d) $@ " -o $@ "$<" "../XDK.xn"
	@echo 'Finished building: $<'
	@echo ' '


