/*
 *  Copyright (c) 2009-2021 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import "OCMPassByRefSetter.h"


@implementation OCMPassByRefSetter

// Stores a reference to all OCMPassByRefSetter instances so that OCMArg can
// check for any given pointer whether its an OCMPassByRefSetter without having
// to get the class for the pointer (see #503). The pointers are stored without
// reference count.
static NSHashTable *_OCMPassByRefSetterInstances = NULL;

+ (void)initialize
{
    if(self == [OCMPassByRefSetter class])
    {
        _OCMPassByRefSetterInstances = [[NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality] retain];
    }
}

+ (BOOL)isPassByRefSetterInstance:(void *)ptr
{
    @synchronized(_OCMPassByRefSetterInstances)
    {
        return NSHashGet(_OCMPassByRefSetterInstances, ptr) != NULL;
    }
}

- (id)initWithValue:(id)aValue
{
    if((self = [super init]))
    {
        value = [aValue retain];
        @synchronized(_OCMPassByRefSetterInstances)
        {
            NSHashInsertKnownAbsent(_OCMPassByRefSetterInstances, self);
        }
    }

    return self;
}

- (id)initWithBlock:(id(^)(void))aBlock{
    if((self = [super init]))
    {
        block = [aBlock copy];
        @synchronized(_OCMPassByRefSetterInstances)
        {
            NSHashInsertKnownAbsent(_OCMPassByRefSetterInstances, self);
        }
    }

    return self;
}

- (void)dealloc
{
    [value release];
    [block release];
    @synchronized(_OCMPassByRefSetterInstances)
    {
        NSHashRemove(_OCMPassByRefSetterInstances, self);
    }
    [super dealloc];
}

- (void)handleArgument:(id)arg
{
    void *pointerValue = [arg pointerValue];
    if(pointerValue != NULL)
    {
        if (block){
           *(id*)pointerValue = block();
        }
        else{
            if([value isKindOfClass:[NSValue class]])
                [(NSValue *)value getValue:pointerValue];
            else
                *(id *)pointerValue = value;
        }
    }
}


@end
