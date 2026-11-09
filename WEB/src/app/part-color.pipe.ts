import { Pipe, PipeTransform } from '@angular/core';

// Presentation only: legacy color identifiers remain unchanged in saved songs.
const PART_COLORS: Record<string, string> = {
  '#910000': 'var(--part-color-1)',
  '#6d28d9': 'var(--part-color-2)',
  '#0e7490': 'var(--part-color-3)',
  '#c2410c': 'var(--part-color-4)',
  '#15803d': 'var(--part-color-5)',
  '#a16207': 'var(--part-color-6)',
};

@Pipe({ name: 'partColor' })
export class PartColorPipe implements PipeTransform {
  transform(color: string): string {
    return PART_COLORS[color.toLowerCase()] ?? color;
  }
}
