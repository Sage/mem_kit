require 'spec_helper'

RSpec.describe MemKit::Profiler do

  describe '#collect' do

    it 'should collect information about the current ObjectSpace' do

      results = MemKit::Profiler.collect

      expect(results).to be_a(Hash)
      expect(results.key?(:total_memory_usage)).to be true
      expect(results.key?(:total_allocations)).to be true
      expect(results.key?(:symbol_count)).to be true
      expect(results.key?(:object_counts)).to be true
      expect(results.key?(:objects)).to be true

    end

    context 'when a limit is specified' do
      it 'should limit the objects[]' do
        results = MemKit::Profiler.collect(limit: 2)

        expect(results).to be_a(Hash)

        expect(results[:objects].length).to be 2
      end
    end

    context 'when symbols are created on mass' do

      it 'they should be garbage collected' do
        results_before = MemKit::Profiler.collect(limit:5)

        symbol_count = results_before[:object_counts][:T_SYMBOL]

        1000.times.each do |i|
          "key_#{i}".to_sym
        end

        results_after = MemKit::Profiler.collect(limit:5)

        expect(results_after[:object_counts][:T_SYMBOL]).to be > 1000

        GC.start

        results_after_gc = MemKit::Profiler.collect(limit:5)

        expect(results_after_gc[:object_counts][:T_SYMBOL]).to be symbol_count
      end

    end

  end

  describe '#format_size' do
    context 'when bytes is less than 0.5KB' do
      let(:bytes) { 450 }
      it 'should be displayed as bytes' do
        expect(MemKit::Profiler.format_size(bytes)).to eq('450 Bytes')
      end
    end
    context 'when bytes is greater than 0.5KB' do
      context 'but less than 100KB' do
        let(:bytes) { 45000 }
        it 'should be displayed as KB' do
          expect(MemKit::Profiler.format_size(bytes)).to eq('45.0 KB')
        end
      end
      context 'and greater than 99KB' do
        let(:bytes) { 100000 }
        it 'should be displayed as MB' do
          expect(MemKit::Profiler.format_size(bytes)).to eq('0.1 MB')
        end
      end
    end
  end

  describe '#format_percentage' do
    context 'when value is 50%' do
      it 'should return 50%' do
        expect(MemKit::Profiler.format_percentage(50, 100)).to eq('50.0%')
      end
    end
    context 'when value is 25%' do
      it 'should return 25%' do
        expect(MemKit::Profiler.format_percentage(25, 100)).to eq('25.0%')
      end
    end
    context 'when value is 66%' do
      it 'should return 66%' do
        expect(MemKit::Profiler.format_percentage(66, 100)).to eq('66.0%')
      end
    end
  end

end