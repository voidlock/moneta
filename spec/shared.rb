shared_examples_for "a read/write Moneta cache" do
  it "reads from keys like a Hash" do
    @cache["key"].should == nil
  end

  it "if key is not available, returns default like a Hash" do
    @cache.default = "default_value"
    @cache["key"].should == "default_value"
  end

  it "writes to a key like a Hash" do
    @cache["key"] = "value"
    @cache["key"].should == "value"
  end

  it "specifies that it is writable via frozen?" do
    @cache.should_not be_frozen
  end

  it "if a key is not available, returns false from key?" do
    @cache.key?("key").should be_false
  end

  it "if a key is available, returns true from key?" do
    @cache["key"] = "value"
    @cache.key?("key").should be_true
  end

  it "if it exists, removes and return an element from the backing store via delete" do
    @cache["key"] = "value"
    @cache.delete("key").should == "value"
    @cache.key?("key").should be_false
  end

  it "if it does not exists, returns nil from delete" do
    @cache.delete("key").should be_nil
  end

  it "removes all keys from the store with clear" do
    @cache["key"] = "value"
    @cache["key2"] = "value2"
    @cache.clear
    @cache.key?("key").should_not be_true
    @cache.key?("key2").should_not be_true
  end

  it "stores values with #store" do
    @cache.store("key", "value")
    @cache["key"].should == "value"
  end

  describe "when retrieving values with #fetch" do
    describe "when value for key is present" do
      before(:each) do
        @cache["b"] = "bee"
      end

      it "returns stored value for given key" do
        @cache.fetch("b").should == "bee"
      end

      it "returns stored value for given key even if default argument is used" do
        @cache.fetch("b", "honey").should == "bee"
      end

      it "returns stored value for given key even if default argument is nil" do
        @cache.fetch("b", nil).should == "bee"
      end

      it "returns stored value for given key even if block is given" do
        @cache.fetch("b") {|k| "honey"}.should == "bee"
      end

      it "returns stored value for given key even if default argument is nil" do
        @cache.fetch("b") {|k| nil}.should == "bee"
      end
    end

    describe "when value for key is not present" do
      it "raises IndexError if there are no other arguments" do
        lambda { @cache.fetch("b") }.should raise_error(IndexError)
      end

      it "returns second argument if given" do
        @cache.fetch("b", "bee").should == "bee"
      end

      it "returns second argument even if second argument is nil" do
        @cache.fetch("b", nil).should == nil
      end

      it "returns value from calling given block" do
        @cache.fetch("b") {|k| "#{k}:bee"}.should == "b:bee"
      end

      it "returns nil if value from calling given block is nil" do
        @cache.fetch("b") {|k| nil}.should == nil
      end
    end
  end

  describe "when storing values with #store, and providing an expiration" do
    before(:each) do
      @cache.store("key", "value", :expires_in => 1)
    end

    shared_examples_for "not expired" do
      it "still has the key" do
        @cache.key?("key").should be_true
      end

      it "returns the value when indexed" do
        @cache["key"].should == "value"
      end

      it "returns the value when fetched" do
        @cache.fetch("key", "value2").should == "value"
      end

      it "returns the value when deleted" do
        @cache.delete("key").should == "value"
      end
    end

    describe "when expired" do
      before(:each) do
        if @native_expires
          sleep 2
        else
          time = Time.now
          Time.stub!(:now).and_return { time + 2 }
        end
      end

      it "no longer has the key" do
        @cache.key?("key").should be_false
      end

      it "returns nil when indexed" do
        @cache["key"].should == nil
      end

      it "returns the default value when fetched" do
        @cache.fetch("key", "value2").should == "value2"
      end

      it "returns nil when deleting the expired key" do
        @cache.delete("key").should == nil
      end
    end

    describe "when not expired" do
      it_should_behave_like "not expired"
    end

    describe "after updating the expiry with update_key, and waiting for the initial expiry to pass" do
      before(:each) do
        @cache.update_key("key", :expires_in => 2)
      end

      it_should_behave_like "not expired"
    end
  end
end